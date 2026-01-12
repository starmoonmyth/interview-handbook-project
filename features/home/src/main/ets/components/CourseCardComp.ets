import { CourseModel } from '../models/CourseModel'

@Component
export struct CourseCardComp {
  @ObjectLink course: CourseModel

  build() {
    Column() {
      Image(this.course.cover)
        .width('100%')
        .height(100)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: 8, topRight: 8 })

      Column() {
        Text(this.course.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })
        
        Row() {
          Text(this.course.teacherName && this.course.teacherName !== '' ? this.course.teacherName : this.course.teacher)
            .fontSize(10)
            .fontColor('#999999')
        }
        .width('100%')
      }
      .padding(8)
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ bottomLeft: 8, bottomRight: 8 })
    }
    .width(160)
    .borderRadius(8)
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .margin({ right: 12 })
  }
}
