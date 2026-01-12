import { hdHttp, HdNav, HdSkeleton, HdSkeletonType, logger, NetworkConfig } from '@itcast/basic'
import { AssignmentModel, CourseModel, CourseData, ChapterData, ResourceData } from '../models/CourseModel'
import { router, promptAction } from '@kit.ArkUI'
import { CourseService } from '../services/CourseService'
import { emitter } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { request } from '@kit.BasicServicesKit'
import { common, Want, wantConstant } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@Component
export struct CourseDetailComp {
  @State list: AssignmentModel[] = []
  @State examList: AssignmentModel[] = []
  @State courseId: number = 0
  @State course: CourseModel | null = null
  @State loading: boolean = true
  @State downloadedFiles: Map<string, boolean> = new Map() // 记录已下载的文件

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params.id) {
      this.courseId = Number(params.id)
      this.loadData()
    }
  }

  loadData() {
    this.loading = true
    logger.info(`CourseDetail: Start loading course detail for courseId: ${this.courseId}`)
    CourseService.getCourseDetail(this.courseId)
      .then(res => {
        logger.info(`CourseDetail: API Response: ${JSON.stringify(res)}`)
        const courseData = res.data as CourseData
        this.course = new CourseModel(courseData)
        if (this.course.isJoined) {
          this.getAssignments()
        } else {
          this.loading = false
        }
      })
      .catch((err: BusinessError) => {
        logger.error('CourseDetail', 'loadData failed', err.message)
        promptAction.showToast({ message: '加载失败: ' + err.message })
        this.loading = false
      })
  }

  getAssignments() {
    CourseService.getAssignmentList(this.courseId)
      .then(res => {
        this.list = res.data
      })
      .finally(() => {
        this.loading = false
      })
  }

  joinCourse() {
    CourseService.joinCourse(this.courseId).then(() => {
      promptAction.showToast({ message: '参加成功' })
      if (this.course) {
        this.course.isJoined = true
        // 重新加载课程详情以获取最新数据 (包括最新人数)
        this.loadData()
      }
      this.getAssignments()
      // 通知我的课堂页面刷新
      emitter.emit({ eventId: 10001 })
    })
  }

  // 检查文件是否已下载
  checkFileExists(filename: string): boolean {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filesDir = context.filesDir;
      const filePath = `${filesDir}/${filename}`;
      return fileIo.accessSync(filePath);
    } catch (e) {
      return false;
    }
  }

  // 下载文件
  async downloadFile(url: string, filename: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const filesDir = context.filesDir;
    const filePath = `${filesDir}/${filename}`;

    try {
      if (this.checkFileExists(filename)) {
        // 文件已存在，直接打开
        this.openFile(filePath, filename);
        return;
      }

      promptAction.showToast({ message: '开始下载...' });
      
      // 处理相对路径
      let downloadUrl = url;
      if (!downloadUrl.startsWith('http')) {
         let baseUrl = NetworkConfig.BASE_URL;
         if (baseUrl.endsWith('/')) {
            baseUrl = baseUrl.slice(0, -1);
         }
         if (!downloadUrl.startsWith('/')) {
            downloadUrl = `${baseUrl}/${downloadUrl}`;
         } else {
            downloadUrl = `${baseUrl}${downloadUrl}`;
         }
      }

      request.downloadFile(context, {
        url: downloadUrl,
        filePath: filePath
      }).then((downloadTask) => {
        downloadTask.on('complete', () => {
          promptAction.showToast({ message: '下载完成' });
          this.downloadedFiles.set(filename, true); // 更新状态
        })
        downloadTask.on('fail', (err) => {
          logger.error('Download', `Failed: ${err}`);
          promptAction.showToast({ message: '下载失败' });
        })
      }).catch((err: BusinessError) => {
        logger.error('Download', `Request failed: ${err.message}`);
        promptAction.showToast({ message: '下载请求失败' });
      })
    } catch (error) {
      logger.error('Download', `Error: ${JSON.stringify(error)}`);
    }
  }

  // 打开文件
  openFile(filePath: string, filename: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const uri = fileUri.getUriFromPath(filePath);
    
    // 根据文件后缀推断 MIME type
    let type = '*/*';
    const lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.pdf')) type = 'application/pdf';
    else if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) type = 'application/msword';
    
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: type,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
    };

    context.startAbility(want).catch((err: BusinessError) => {
      logger.error('OpenFile', `StartAbility failed: ${err.message}`);
      promptAction.showToast({ message: '无法打开该文件，请安装WPS或其他阅读器' });
    });
  }

  getFileName(url: string): string {
    return url.split('/').pop() || 'unknown_file';
  }

  isResourceDownloaded(url: string): boolean {
    const filename = this.getFileName(url);
    return this.downloadedFiles.get(filename) || this.checkFileExists(filename);
  }

  @State currentTabIndex: number = 0

  @Builder
  ChapterItemBuilder(chapter: ChapterData) {
    Column() {
      Text(chapter.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ top: 16, bottom: 8 })

      ForEach(chapter.resources, (resource: ResourceData) => {
        Row() {
          Image(resource.type === 'VIDEO' ? $r('app.media.ic_mine_file') : $r('app.media.ic_mine_file'))
            .width(20)
            .height(20)
            .margin({ right: 8 })
            .fillColor('#007DFF')

          Text(resource.title)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (resource.type === 'VIDEO') {
             Text('播放')
               .fontSize(12)
               .fontColor('#007DFF')
               .padding({ left: 8, right: 8, top: 4, bottom: 4 })
               .backgroundColor('#E6F2FF')
               .borderRadius(4)
          } else if (resource.type === 'WORD' || resource.type === 'PDF') {
             Text(this.isResourceDownloaded(resource.url) ? '打开' : '下载')
               .fontSize(12)
               .fontColor('#007DFF')
               .padding({ left: 8, right: 8, top: 4, bottom: 4 })
               .backgroundColor('#E6F2FF')
               .borderRadius(4)
               .onClick((): void => {
                  CourseService.logStudy(resource.id).then(() => {
                    // 通知刷新进度
                    emitter.emit({ eventId: 10001 })
                  }).catch((e: BusinessError): void => {
                    logger.error('logStudy failed', JSON.stringify(e))
                  })
                  this.downloadFile(resource.url, this.getFileName(resource.url));
               })
          }
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .border({ width: { bottom: 1 }, color: '#F5F5F5' })
        .onClick((): void => {
           // 记录学习进度
           CourseService.logStudy(resource.id).then(() => {
             // 通知刷新进度
             emitter.emit({ eventId: 10001 })
           }).catch((e: BusinessError): void => {
             logger.error('logStudy failed', JSON.stringify(e))
           })

           if (resource.type === 'VIDEO') {
             router.pushUrl({
               url: 'pages/VideoPlayPage',
               params: { 
                 url: resource.url, 
                 title: resource.title 
               }
             })
           } else if (resource.type !== 'WORD' && resource.type !== 'PDF') {
             // 其他未知类型文件跳转到 WebBrowserPage 预览
             router.pushUrl({
               url: 'pages/WebBrowserPage',
               params: {
                 url: resource.url,
                 title: resource.title,
                 type: resource.type
               }
             })
           }
           // Word/PDF 的点击已经在内部 Text onClick 处理，或者这里也可以统一处理
           // 为了体验，点击整行也可以触发下载/打开
           if (resource.type === 'WORD' || resource.type === 'PDF') {
              const filename = resource.url.split('/').pop() || `file_${Date.now()}`;
              this.downloadFile(resource.url, filename);
           }
        })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .margin({ bottom: 8 })
  }

  @Builder
  AssignmentItemBuilder(item: AssignmentModel) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(500)
          .margin({ bottom: 8 })
        
        Row() {
          if (item.status === 'NOT_STARTED') {
             Text('未开始')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#CCCCCC')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'IN_PROGRESS') {
             Text('进行中')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#007DFF')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'ENDED') {
             Text('已截止')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#FF4D4F')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'SUBMITTED') {
             Text('已提交')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#52C41A')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'GRADED') {
             Text('已批改')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#52C41A')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          }

          Text(`发布时间: ${item.createdAt}`)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      Image($r('app.media.ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
    .onClick(() => {
      // 状态判断
      if (item.status === 'NOT_STARTED') {
        promptAction.showToast({ message: '作业尚未开始' })
        return
      }
      // 已结束且未提交，不可做（但根据需求通常可查看题目，这里提示已截止）
      // 实际上 ENDED 状态下，如果未提交过，是不能提交的。如果已提交过，状态会是 SUBMITTED/GRADED
      // 这里简单处理：如果 ENDED，提示已截止；如果 SUBMITTED/GRADED，跳转查看结果（暂未实现结果页，先提示）
      
      if (item.status === 'ENDED') {
         promptAction.showToast({ message: '作业已截止' })
         // 可选：允许查看题目但不允许提交
         return
      }

      if (item.status === 'SUBMITTED' || item.status === 'GRADED') {
         // 跳转到结果详情页
          const type = item.type === 'EXAM' ? 'exam' : 'assignment'
          router.pushUrl({
            url: 'pages/AssignmentResultPage',
            params: { assignmentId: item.id, type: type, title: item.title }
          })
          return
      }

      // 跳转到做题页面
      router.pushUrl({
        url: 'pages/AssignmentPracticePage',
        params: { assignmentId: item.id, title: item.title }
      })
    })
  }

  @Builder
  TabsBuilder() {
    Row() {
      ForEach(['全部', '课堂', '作业'], (item: string, index: number) => {
        Column() {
          Text(item)
            .fontSize(16)
            .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === index ? '#000000' : '#666666')
            .margin({ bottom: 8 })
          
          if (this.currentTabIndex === index) {
            Divider()
              .strokeWidth(3)
              .color('#007DFF')
              .width(24)
              .lineCap(LineCapStyle.Round)
          } else {
            Divider()
              .strokeWidth(3)
              .color(Color.Transparent)
              .width(24)
          }
        }
        .onClick(() => {
          this.currentTabIndex = index
        })
        .margin({ right: 24 })
      })
    }
    .width('100%')
    .padding({ left: 16, top: 16, bottom: 8 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#F5F5F5' })
  }

  @Builder
  ContentBuilder() {
    if (this.currentTabIndex === 0) { // 全部
      Column() {
        if (this.course?.chapters && this.course.chapters.length > 0) {
          Text('课程章节')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 8 })
          ForEach(this.course.chapters, (chapter: ChapterData) => {
            this.ChapterItemBuilder(chapter)
          })
        }
        
        if (this.course?.isJoined && this.list.length > 0) {
          Text('课程作业')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 8 })
          List() {
            ForEach(this.list, (item: AssignmentModel) => {
              ListItem() {
                this.AssignmentItemBuilder(item)
              }
            })
          }
          .padding({ left: 16, right: 16, bottom: 20 })
        }
      }
    } else if (this.currentTabIndex === 1) { // 课堂
      Column() {
        if (this.course?.chapters && this.course.chapters.length > 0) {
          ForEach(this.course.chapters, (chapter: ChapterData) => {
            this.ChapterItemBuilder(chapter)
          })
        } else {
          this.EmptyBuilder('暂无课程内容')
        }
      }
      .padding({ top: 16 })
    } else if (this.currentTabIndex === 2) { // 作业
      Column() {
        if (this.course?.isJoined) {
          if (this.list.length > 0) {
            List() {
              ForEach(this.list, (item: AssignmentModel) => {
                ListItem() {
                  this.AssignmentItemBuilder(item)
                }
              })
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 20 })
          } else {
            this.EmptyBuilder('暂无作业')
          }
        } else {
          this.EmptyBuilder('请先参加课程')
        }
      }
    } else if (this.currentTabIndex === 3) { // 考试
      Column() {
        if (this.course?.isJoined) {
          if (this.examList.length > 0) {
            List() {
              ForEach(this.examList, (item: AssignmentModel) => {
                ListItem() {
                  this.AssignmentItemBuilder(item)
                }
              })
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 20 })
          } else {
            this.EmptyBuilder('暂无考试')
          }
        } else {
          this.EmptyBuilder('请先参加课程')
        }
      }
    }
  }

  @Builder
  EmptyBuilder(text: string) {
    Column() {
      Image($r('app.media.ic_mine_file'))
        .width(80)
        .height(80)
        .fillColor('#EEEEEE')
        .margin({ bottom: 16 })
      Text(text)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      HdNav({ title: this.course?.title || '课程详情' })
      
      if (this.loading && !this.course) {
        Column() {
          HdSkeleton({ rows: 3 })
        }
        .padding(16)
      } else if (this.course) {
        // 固定头部：封面 + 信息
        Column() {
          Image(this.course.cover || $r('app.media.ic_public_image'))
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
          
          Column({ space: 8 }) {
            Text(this.course.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            
            Row() {
              Text(`讲师: ${this.course.teacherName && this.course.teacherName !== '' ? this.course.teacherName : this.course.teacher}`)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ right: 16 })
              Text(`${this.course.studentCount ?? 0} 人已参加`)
                .fontSize(14)
                .fontColor('#666666')
            }
            
            Text(this.course.description || '暂无简介')
              .fontSize(14)
              .fontColor('#333333')
              .lineHeight(20)
              .margin({ top: 8 })
          }
          .padding(16)
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(Color.White)
          .margin({ bottom: 8 })
        }

        // Tab 导航
        this.TabsBuilder()

        // 内容区域 (可滚动)
        Scroll() {
          this.ContentBuilder()
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .edgeEffect(EdgeEffect.Spring)

        // 底部按钮
        if (!this.course.isJoined) {
          Column() {
            Button('立即参加')
              .width('100%')
              .height(44)
              .backgroundColor('#007DFF')
              .onClick(() => {
                this.joinCourse()
              })
          }
          .padding(16)
          .backgroundColor(Color.White)
          .border({ width: { top: 1 }, color: '#EEEEEE' })
        }
      } else {
        // 加载失败或无数据
        Column() {
          Text('无法加载课程详情')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
