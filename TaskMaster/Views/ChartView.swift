import SwiftUI

// 条形图数据结构
struct BarChartData: Identifiable {
  var id = UUID()
  var label: String
  var value: Double
  var color: Color
}

// 折线图数据结构
struct LineChartData: Identifiable {
  var id = UUID()
  var date: Date
  var value: Double
}

// 条形图视图
struct BarChartView: View {
  var data: [BarChartData]
  var title: String

  // 获取最大值以确定比例
  private var maxValue: Double {
    data.map { $0.value }.max() ?? 1.0
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .padding(.bottom, 4)

      ForEach(data) { item in
        HStack {
          Text(item.label)
            .frame(width: 60, alignment: .leading)
            .font(.footnote)

          ZStack(alignment: .leading) {
            // 背景条
            Rectangle()
              .fill(Color(.systemGray5))
              .frame(height: 20)
              .cornerRadius(4)

            // 数据条
            Rectangle()
              .fill(item.color)
              .frame(width: max(CGFloat(item.value / maxValue) * 200, 10), height: 20)
              .cornerRadius(4)
          }

          Text("\(Int(item.value))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(10)
    .shadow(radius: 1)
  }
}

// 折线图视图
struct LineChartView: View {
  var data: [LineChartData]
  var title: String
  var lineColor: Color = .blue

  // 获取日期格式化器 - 短格式日期
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter
  }()

  // 获取最大值以确定比例
  private var maxValue: Double {
    max(data.map { $0.value }.max() ?? 1.0, 1.0)
  }

  // 获取排序后的数据
  private var sortedData: [LineChartData] {
    data.sorted { $0.date < $1.date }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .padding(.bottom, 4)

      // 绘制图表
      GeometryReader { geometry in
        let width = geometry.size.width
        let height = geometry.size.height - 40

        ZStack(alignment: .topLeading) {
          // 网格线
          VStack(spacing: height / 4) {
            ForEach(0..<5) { i in
              Divider()
                .frame(height: 1)
                .opacity(0.5)
            }
          }

          // 数据线
          if sortedData.count > 1 {
            Path { path in
              let spacing = width / CGFloat(sortedData.count - 1)

              path.move(
                to: CGPoint(
                  x: 0,
                  y: height - CGFloat(sortedData[0].value / maxValue) * height
                ))

              for (index, item) in sortedData.dropFirst().enumerated() {
                let xPosition = spacing * CGFloat(index + 1)
                let yPosition = height - CGFloat(item.value / maxValue) * height

                path.addLine(to: CGPoint(x: xPosition, y: yPosition))
              }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // 数据点
            ForEach(0..<sortedData.count, id: \.self) { index in
              let item = sortedData[index]
              let spacing = width / CGFloat(sortedData.count - 1)
              let xPosition = index == 0 ? 0 : spacing * CGFloat(index)
              let yPosition = height - CGFloat(item.value / maxValue) * height

              Circle()
                .fill(lineColor)
                .frame(width: 8, height: 8)
                .position(x: xPosition, y: yPosition)
            }
          }
        }
        .frame(height: height)

        // X轴标签
        HStack(spacing: 0) {
          ForEach(0..<sortedData.count, id: \.self) { index in
            let item = sortedData[index]

            Text(dateFormatter.string(from: item.date))
              .font(.caption2)
              .frame(width: width / CGFloat(sortedData.count))
              .rotationEffect(.degrees(-45))
              .offset(y: 10)
          }
        }
        .frame(width: width)
        .offset(y: height)
      }
      .frame(height: 200)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(10)
    .shadow(radius: 1)
  }
}

// 环形图视图
struct PieChartView: View {
  var data: [BarChartData]
  var title: String

  // 获取总量
  private var total: Double {
    data.map { $0.value }.reduce(0, +)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .padding(.bottom, 4)

      HStack(alignment: .center) {
        // 环形图
        ZStack {
          ForEach(0..<data.count, id: \.self) { index in
            PieSliceView(
              startAngle: startAngle(for: index),
              endAngle: endAngle(for: index),
              color: data[index].color
            )
          }

          // 中间的圆形，形成环形
          Circle()
            .fill(Color(.systemBackground))
            .frame(width: 60, height: 60)

          // 中间显示总数
          Text("\(Int(total))")
            .font(.headline)
            .foregroundColor(.primary)
        }
        .frame(width: 120, height: 120)

        // 图例
        VStack(alignment: .leading, spacing: 8) {
          ForEach(data) { item in
            HStack {
              RoundedRectangle(cornerRadius: 3)
                .fill(item.color)
                .frame(width: 16, height: 16)

              Text(item.label)
                .font(.footnote)

              Spacer()

              Text("\(Int(item.value))")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
          }
        }
        .padding(.leading, 8)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(10)
    .shadow(radius: 1)
  }

  // 获取开始角度
  private func startAngle(for index: Int) -> Double {
    var angle: Double = 0

    for i in 0..<index {
      angle += 360 * (data[i].value / total)
    }

    return angle
  }

  // 获取结束角度
  private func endAngle(for index: Int) -> Double {
    startAngle(for: index) + 360 * (data[index].value / total)
  }
}

// 饼图的切片视图
struct PieSliceView: View {
  var startAngle: Double
  var endAngle: Double
  var color: Color

  var body: some View {
    GeometryReader { geometry in
      let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
      let radius = min(geometry.size.width, geometry.size.height) / 2

      Path { path in
        path.move(to: center)
        path.addArc(
          center: center,
          radius: radius,
          startAngle: .degrees(startAngle - 90),
          endAngle: .degrees(endAngle - 90),
          clockwise: false
        )
        path.closeSubpath()
      }
      .fill(color)
    }
  }
}

// MARK: - 预览
struct ChartView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      VStack(spacing: 20) {
        // 条形图预览
        BarChartView(
          data: [
            BarChartData(label: "工作", value: 10, color: .blue),
            BarChartData(label: "学习", value: 5, color: .green),
            BarChartData(label: "生活", value: 8, color: .orange),
          ],
          title: "任务分类统计"
        )

        // 折线图预览
        LineChartView(
          data: [
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, value: 2),
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, value: 5),
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, value: 3),
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, value: 7),
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, value: 4),
            LineChartData(
              date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, value: 6),
            LineChartData(date: Date(), value: 8),
          ],
          title: "每日完成任务趋势"
        )

        // 环形图预览
        PieChartView(
          data: [
            BarChartData(label: "高", value: 8, color: .red),
            BarChartData(label: "中", value: 12, color: .orange),
            BarChartData(label: "低", value: 5, color: .green),
          ],
          title: "任务优先级分布"
        )
      }
      .padding()
    }
  }
}
