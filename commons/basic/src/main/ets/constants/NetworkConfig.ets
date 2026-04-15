export class NetworkConfig {
  /**
   * 接口基础地址配置
   * Base URL Configuration
   */

  /**
   * 模式 1: 在线生产环境接口 (原项目默认)
   * Mode 1: Online Production API (Original Default)
   * 适用于：查看原有数据、测试 UI 展示
   */
  // static readonly BASE_URL = 'https://api-harmony-teach.itheima.net/hm/'

  /**
   * 模式 2: 本地 Spring Boot 开发环境
   * Mode 2: Local Spring Boot Dev Server
   * 适用于：对接您自己编写的后台网页
   *
   * 配置说明 / Configuration Steps:
   * 1. 获取本机局域网 IP (Get Local IP):
   *    - Windows: 在终端运行 `ipconfig`，查看 IPv4 地址
   *    - Mac/Linux: 在终端运行 `ifconfig`，查看 en0 或 en1 的 inet 地址
   * 2. 替换下方的 IP 地址 (Replace IP below):
   *    - 将 '192.168.1.XX' 替换为您真实的局域网 IP
   * 3. 端口号 (Port):
   *    - 默认 Spring Boot 端口为 8080，如有修改请同步更改
   * 4. 网络连通性 (Connectivity):
   *    - 确保手机/模拟器与电脑连接同一 WiFi
   *    - 确保电脑防火墙允许端口访问
   */
  static readonly BASE_URL = 'http://192.168.31.208:8080/hm/'
}
