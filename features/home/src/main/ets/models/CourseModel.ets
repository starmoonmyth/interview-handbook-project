import { NetworkConfig } from '@itcast/basic/src/main/ets/constants/NetworkConfig'

export interface ResourceData {
  id: number
  title: string
  type: string
  url: string
}

export interface ChapterData {
  id: number
  title: string
  resources: ResourceData[]
}

export interface CourseData {
  id: number
  title: string
  cover: string
  teacher: string
  teacherName?: string
  description: string
  isJoined?: boolean
  studentCount?: number
  progress?: number
  lastStudyTime?: string
  chapters?: ChapterData[]
}

@Observed
export class CourseModel {
  id: number = 0
  title: string = ''
  cover: string = ''
  teacher: string = ''
  teacherName: string = ''
  description: string = ''
  isJoined: boolean = false
  studentCount: number = 0
  progress: number = 0
  lastStudyTime: string = ''
  chapters: ChapterData[] = []

  constructor(model: CourseData) {
    this.id = model.id ?? 0
    this.title = model.title ?? ''
    this.cover = this.resolveUrl(model.cover ?? '')
    
    this.teacher = model.teacher ?? ''
    this.teacherName = model.teacherName ?? ''
    this.description = model.description ?? ''
    this.isJoined = model.isJoined ?? false
    this.studentCount = model.studentCount ?? 0
    this.progress = model.progress ?? 0
    this.lastStudyTime = model.lastStudyTime ?? ''
    
    // 手动映射 chapters，避免对象展开错误
    if (model.chapters) {
      this.chapters = model.chapters.map(chapter => {
        const newChapter: ChapterData = {
          id: chapter.id,
          title: chapter.title,
          resources: []
        }
        
        if (chapter.resources) {
          newChapter.resources = chapter.resources.map(res => {
            const newRes: ResourceData = {
              id: res.id,
              title: res.title,
              type: res.type,
              url: this.resolveUrl(res.url)
            }
            return newRes
          })
        }
        
        return newChapter
      })
    } else {
      this.chapters = []
    }
  }

  /**
   * 解析 URL，处理 localhost、局域网 IP 和相对路径
   */
  private resolveUrl(url: string): string {
    if (!url) return ''
    
    // 匹配 localhost, 127.0.0.1, 以及所有常见的局域网 IP 段
    const localIpRegex = /^https?:\/\/(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+)(:\d+)?\//

    // 强制处理：如果是相对路径，或者是包含本机局域网 IP 的绝对路径
    if (!url.startsWith('http') || localIpRegex.test(url)) {
      // 移除 BASE_URL 末尾的 'hm/'，获取服务器根地址 (e.g. http://192.168.31.214:8080/)
      const baseUrlRoot = NetworkConfig.BASE_URL.replace(/\/hm\/?$/, '/')
      
      let cleanPath = ''
      
      if (localIpRegex.test(url)) {
         cleanPath = url.replace(localIpRegex, '')
      } else {
         // 移除 url 开头的 '/' (如果有)
         cleanPath = url.startsWith('/') ? url.substring(1) : url
      }
      
      return baseUrlRoot + cleanPath
    }
    return url
  }
}

export interface CourseHistoryData {
  id: number
  courseId: number
  sectionId: number
  progress: number
  lastLearnTime: string
  courseName: string
  sectionName: string
}

export class CourseHistoryModel implements CourseHistoryData {
  id: number = 0
  courseId: number = 0
  sectionId: number = 0
  progress: number = 0
  lastLearnTime: string = ''
  courseName: string = ''
  sectionName: string = ''

  constructor(model: CourseHistoryData) {
    this.id = model.id ?? 0
    this.courseId = model.courseId ?? 0
    this.sectionId = model.sectionId ?? 0
    this.progress = model.progress ?? 0
    this.lastLearnTime = model.lastLearnTime ?? ''
    this.courseName = model.courseName ?? ''
    this.sectionName = model.sectionName ?? ''
  }
}

export interface AssignmentModel {
  id: number
  courseId: number
  title: string
  description: string
  startTime: string
  endTime: string
  status: string // NOT_STARTED, IN_PROGRESS, ENDED, SUBMITTED, GRADED
  type: string // HOMEWORK, EXAM
  createdAt: string
}

// 题目数据接口
export interface AssignmentQuestionData {
  id: number
  type: string // choice, blank, qa
  stem: string
  options?: string // JSON string for choice options
  score: number
  
  // 兼容 Result 页面的额外字段 (可选)
  standardAnswer?: string
  studentAnswer?: string
  isCorrect?: boolean
  answer?: string // 某些 API 可能返回 answer
}

@Observed
export class AssignmentQuestionModel implements AssignmentQuestionData {
  id: number = 0
  type: string = ''
  stem: string = ''
  options?: string = ''
  score: number = 0
  
  // Extra fields for UI
  userAnswer: string = ''
  
  // 辅助字段：解析后的选项数组 (仅内存使用)
  parsedOptions: string[] = []

  constructor(model: AssignmentQuestionData) {
    this.id = model.id
    this.type = model.type
    this.stem = model.stem
    this.options = model.options
    this.score = model.score
    
    if (this.options) {
      try {
        this.parsedOptions = JSON.parse(this.options)
      } catch (e) {
        this.parsedOptions = []
      }
    }
  }
}

export interface SubmissionData {
  status: string
  score: number
  teacherComment: string
  createdAt: string
}

export interface AssignmentInfoData {
  title: string
  description: string
}

export interface AssignmentResultModel {
  submission: SubmissionData
  assignment: AssignmentInfoData
  questions: Array<AssignmentQuestionData>
}

export interface StudentProgressData {
  id: number
  username: string
  name?: string
  progress: number
}

export interface StudyInfoData {
  passRate: number
  courseCount: number
  pendingTasks: number
}
