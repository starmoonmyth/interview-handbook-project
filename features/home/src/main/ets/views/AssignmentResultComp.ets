import { CourseService } from '../services/CourseService'
import { AssignmentResultModel, AssignmentQuestionData } from '../models/CourseModel'
import { HdNav, HdSkeleton, logger } from '@itcast/basic'
import { router, promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'

@Component
export struct AssignmentResultComp {
  @State assignmentId: number = 0
  @State type: string = 'assignment' // 'assignment' or 'exam'
  @State title: string = '结果详情'
  @State result: AssignmentResultModel | null = null
  @State loading: boolean = true

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params.assignmentId) {
      this.assignmentId = Number(params.assignmentId)
      this.type = (params.type as string) || 'assignment'
      this.title = (params.title as string) || '结果详情'
      this.loadData()
    }
  }

  loadData() {
    this.loading = true
    const api = this.type === 'exam' ? CourseService.getExamResult(this.assignmentId) : CourseService.getAssignmentResult(this.assignmentId)
    
    api.then(res => {
        this.result = res.data
        logger.info('AssignmentResult', JSON.stringify(this.result))
      })
      .catch((err: BusinessError) => {
         logger.error('AssignmentResult', 'Load failed', JSON.stringify(err))
         promptAction.showToast({ message: '无法加载结果' })
      })
      .finally(() => {
        this.loading = false
      })
  }

  @Builder
  StatusHeader() {
    if (this.result) {
      Column() {
        if (this.result.submission && this.result.submission.status === 'GRADED') {
          Text((this.result.submission.score || 0).toString())
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007DFF')
          Text(`得分`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
          
          if (this.result.submission.teacherComment) {
            Text(`评语: ${this.result.submission.teacherComment}`)
              .fontSize(14)
              .fontColor('#333333')
              .margin({ top: 12 })
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .width('100%')
          }
        } else {
          Image($r('app.media.ic_mine_history')) // Temporary icon or reuse existing
            .width(64)
            .height(64)
            .fillColor('#CCCCCC')
          Text('暂未批改')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16 })
          Text('老师正在努力批改中，请耐心等待...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  QuestionItem(question: AssignmentQuestionData, index: number) {
    Column() {
      // Header: Type + Index + Score/Status
      Row() {
        Row() {
          Text(`${index + 1}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ right: 8 })
          
          Text(question.type === 'choice' ? '选择题' : (question.type === 'blank' ? '填空题' : '简答题'))
            .fontSize(12)
            .fontColor('#007DFF')
            .backgroundColor('#E6F2FF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
        }
        
        Blank()

        if (this.result?.submission?.status === 'GRADED') {
          Row() {
            if (question.isCorrect) {
              Image($r('app.media.ic_public_ok'))
                .width(16)
                .height(16)
                .fillColor('#52C41A')
                .margin({ right: 4 })
              // 分数暂时未知，因为 API 没返回每题得分，暂显示 "正确" 或隐藏分值
              Text('正确')
                .fontSize(14)
                .fontColor('#52C41A')
            } else {
              Image($r('app.media.ic_public_close'))
                .width(16)
                .height(16)
                .fillColor('#FF4D4F')
                .margin({ right: 4 })
              Text('错误')
                .fontSize(14)
                .fontColor('#FF4D4F')
            }
          }
        } else {
           Text('待批改')
             .fontSize(14)
             .fontColor('#999999')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // Stem
      Text(question.stem || '未知题目')
        .fontSize(16)
        .fontColor('#333333')
        .lineHeight(24)
        .margin({ bottom: 12 })

      // Options (for choice)
      if (question.type === 'choice') {
        Column({ space: 8 }) {
           // Parse options safely
           ForEach(this.parseOptions(question.options || ''), (opt: string, idx: number) => {
             Row() {
               Text(String.fromCharCode(65 + idx) + '.')
                 .fontSize(14)
                 .fontColor('#666666')
                 .margin({ right: 8 })
               Text(opt)
                 .fontSize(14)
                 .fontColor('#333333')
             }
             .width('100%')
           })
        }
        .padding({ bottom: 12 })
      }

      Divider().color('#F0F0F0').margin({ bottom: 12 })

      // User Answer & Correct Answer
      Column({ space: 8 }) {
        Row() {
          Text('你的答案：')
            .fontSize(14)
            .fontColor('#666666')
          Text(question.studentAnswer ? question.studentAnswer : '未作答')
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        if (this.result?.submission?.status === 'GRADED') {
          Row() {
            Text('正确答案：')
              .fontSize(14)
              .fontColor('#666666')
            Text(question.standardAnswer || question.answer || '')
              .fontSize(14)
              .fontColor('#52C41A')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
      }
      .backgroundColor('#F9F9F9')
      .padding(12)
      .borderRadius(6)

    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  parseOptions(json: string): string[] {
    try {
      if (!json) return []
      return JSON.parse(json)
    } catch (e) {
      return []
    }
  }

  build() {
    Column() {
      HdNav({ title: this.title })
      
      if (this.loading) {
        Column() {
          HdSkeleton({ rows: 5 })
        }
        .padding(16)
      } else if (this.result) {
        List() {
          ListItem() {
            this.StatusHeader()
          }
          
          if (this.result.questions) {
            ForEach(this.result.questions, (question: AssignmentQuestionData, index: number) => {
              ListItem() {
                this.QuestionItem(question, index)
              }
            })
          } else {
             ListItem() {
                Column() {
                  Text('暂无题目详情')
                    .fontSize(14)
                    .fontColor('#999999')
                    .margin({ top: 20 })
                }.width('100%').alignItems(HorizontalAlign.Center)
             }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F5F5F5')
      } else {
        Column() {
          Text('暂无结果数据')
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
