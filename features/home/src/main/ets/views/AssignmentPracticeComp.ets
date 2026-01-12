import { logger } from '@itcast/basic'
  import { hdHttp, HdNav, HdSkeleton } from '@itcast/basic'
import { AssignmentQuestionModel } from '../models/CourseModel'
import { router, promptAction } from '@kit.ArkUI'
import { CourseService, SubmitAssignmentParams } from '../services/CourseService'
import { emitter } from '@kit.BasicServicesKit'

@Component
export struct AssignmentPracticeComp {
  @State assignmentId: number = 0
  @State title: string = '作业练习'
  @State questions: AssignmentQuestionModel[] = []
  @State currentIndex: number = 0
  @State loading: boolean = true

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.assignmentId = params.assignmentId as number
      this.title = params.title as string
      this.loadQuestions()
    }
  }

  loadQuestions() {
    this.loading = true
    logger.info(`AssignmentPracticeComp: Start loading questions for assignmentId: ${this.assignmentId}`)
    CourseService.getAssignmentQuestions(this.assignmentId)
      .then(res => {
        logger.info(`AssignmentPracticeComp: API Response: ${JSON.stringify(res)}`)
        // 接口返回的是 PageResult 结构，题目数据在 records 字段中
        const records = res.data?.records || []
        if (records.length > 0) {
           this.questions = records.map(item => new AssignmentQuestionModel(item))
           logger.info(`AssignmentPracticeComp: Loaded ${this.questions.length} questions`)
        } else {
           logger.warn('AssignmentPracticeComp: No questions found in response data (records is empty)')
           this.questions = []
        }
      })
      .catch((err: Error) => {
        logger.error(`AssignmentPracticeComp: Failed to load questions: ${JSON.stringify(err)}`)
        promptAction.showToast({ message: `加载题目失败: ${err.message}` })
      })
      .finally(() => {
        this.loading = false
      })
  }

  submit() {
    const answers: Record<string, string> = {}
    this.questions.forEach(q => {
      answers[q.id.toString()] = q.userAnswer
    })

    CourseService.submitAssignment({
      assignmentId: this.assignmentId,
      answers: answers
    } as SubmitAssignmentParams).then(() => {
       promptAction.showToast({ message: '提交成功' })
       // 通知刷新
       emitter.emit({ eventId: 10001 })
       router.back()
    }).catch((err: Error) => {
       promptAction.showToast({ message: '提交失败: ' + err.message })
    })
  }

  build() {
    Column() {
      HdNav({ title: this.title })
      
      if (this.loading) {
        Column() {
          HdSkeleton({ rows: 5 })
        }
        .padding(16)
      } else if (this.questions.length > 0) {
        Column() {
          QuestionItemView({
            question: this.questions[this.currentIndex],
            index: this.currentIndex,
            total: this.questions.length
          })
          
          Blank()
          
          Row() {
            Button('上一题')
              .onClick(() => {
                if (this.currentIndex > 0) this.currentIndex--
              })
              .enabled(this.currentIndex > 0)
              .backgroundColor(this.currentIndex > 0 ? '#007DFF' : '#CCCCCC')
              .width('40%')
            
            Blank()
            
            Button(this.currentIndex === this.questions.length - 1 ? '提交' : '下一题')
              .onClick(() => {
                if (this.currentIndex < this.questions.length - 1) {
                  this.currentIndex++
                } else {
                  this.submit()
                }
              })
              .backgroundColor('#007DFF')
              .width('40%')
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          Text('暂无题目')
            .fontSize(16)
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

@Component
struct QuestionItemView {
  @Watch('onQuestionChange')
  @ObjectLink question: AssignmentQuestionModel
  @Prop index: number
  @Prop total: number
  @State currentAnswer: string = ''

  // 监听 question 变化，当题目切换时重置输入框
  onQuestionChange() {
    this.currentAnswer = this.question.userAnswer || ''
  }

  aboutToAppear() {
    // 初始化时加载已有答案
    this.currentAnswer = this.question.userAnswer || ''
  }

  // 移除多余的 @Watch 声明，因为已经在上方属性定义处声明了
  // @Watch('onQuestionChange') 
  // @ObjectLink question: AssignmentQuestionModel

  // onQuestionChange() { ... } 

  build() {
    Column() {
      // 题目类型标签
      Row() {
        Text(this.getTypeName(this.question.type))
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
          .margin({ right: 8 })
        
        Text(`第 ${this.index + 1} / ${this.total} 题`)
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 题干
      Text(this.question.stem)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .lineHeight(24)
        .margin({ bottom: 24 })

      // 选项或输入区域
      if (this.question.type === 'choice') {
        // 单选/多选
        this.OptionsContent()
      } else {
        // 填空/简答
        TextArea({ placeholder: '请输入答案...', text: this.currentAnswer })
          .height(150)
          .width('100%')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value) => {
            this.currentAnswer = value
          })
        
        Button('保存回答')
          .onClick(() => {
            this.question.userAnswer = this.currentAnswer
            promptAction.showToast({ message: '已保存' })
          })
          .margin({ top: 16 })
          .width('100%')
          .backgroundColor('#E6F2FF')
          .fontColor('#007DFF')
      }
    }
    .padding(16)
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder
  OptionsContent() {
    Column({ space: 12 }) {
      ForEach(this.question.parsedOptions, (option: string, index: number) => {
        Row() {
          Text(String.fromCharCode(65 + index) + '.') // A, B, C...
            .fontWeight(FontWeight.Bold)
            .margin({ right: 8 })
          Text(option)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.question.userAnswer === option ? '#E6F2FF' : '#F9F9F9')
        .borderRadius(8)
        .onClick(() => {
           this.question.userAnswer = option
        })
      })
    }
  }

  getTypeName(type: string): string {
    switch (type) {
      case 'choice': return '选择题'
      case 'blank': return '填空题'
      case 'text': return '简答题'
      default: return '未知'
    }
  }
}

@CustomDialog
struct SelectQuestionDialog {
  questions: AssignmentQuestionModel[] = []
  onSelect: (index: number) => void = () => {}
  controller: CustomDialogController

  build() {
    Column() {
      Text('题目列表')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16, top: 16 })
      
      Grid() {
        ForEach(this.questions, (item: AssignmentQuestionModel, index: number) => {
          GridItem() {
            Text(`${index + 1}`)
              .fontSize(16)
              .fontColor(item.userAnswer ? Color.White : '#333')
              .backgroundColor(item.userAnswer ? '#007DFF' : '#F5F5F5')
              .width(40)
              .height(40)
              .textAlign(TextAlign.Center)
              .borderRadius(20)
              .onClick(() => {
                this.onSelect(index)
                this.controller.close()
              })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .height(300)
    }
    .padding({ left: 16, right: 16, bottom: 32 })
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
