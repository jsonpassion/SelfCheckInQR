//
//  HistoryView.swift
//  SelfCheckInQR
//
//  Created by hyunho lee on 2022/03/10.
//

import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct HistoryView: View {
    @Binding var currentDate: Date
    @State var currentMonth: Int = 0
    
    private let ref = Database.database().reference(withPath: "attend-history")
    @State var tasks: [TaskMetaData] = []
    
    var body: some View {
        
        VStack(spacing: 35) {
            
            let days: [String] = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            
            // Calendar header
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(extraDate()[0])
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(extraDate()[1])
                        .font(.title.bold())
                }
                
                Spacer(minLength: 0)
                
                Button {
                    withAnimation{
                        currentMonth -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                
                Button {
                    withAnimation {
                        currentMonth += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // day header
            HStack(spacing: 0) {
                ForEach(days,id: \.self){day in
                    Text(day)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Dates....
            // Lazy Grid..
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            LazyVGrid(columns: columns,spacing: 15) {
                
                // TODO: 날짜 넣기
                ForEach(extractDate()) { value in
                    CardView(value: value)
                        .background(
                            Capsule()
                                .fill(Color("Green"))
                                .padding(.horizontal,8)
                                .opacity(isSameDay(date1: value.date, date2: currentDate) ? 1 : 0)
                        )
                        .onTapGesture {
                            currentDate = value.date
                        }
                }
            }
            
            VStack(spacing: 15) {
                
                Text("출석시간")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity,alignment: .leading)
                if let task = tasks.first(where: { task in
                    return isSameDay(date1: task.taskDate, date2: currentDate)
                }) {
                    ForEach(task.task){task in
                        VStack(alignment: .leading, spacing: 10) {
                            // For Custom Timing...
                            Text(extraStringTime(attendDate: task.time))
                            
                            Text(task.title)
                                .font(.title2.bold())
                        }
                        .padding(.vertical,10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .background(
                            Color("Purple")
                                .opacity(0.5)
                                .cornerRadius(10)
                        )
                    }
                }
                else{
                    Text("체크인 메시지가 없습니다.")
                }
            }
            .padding()
        }
        .onChange(of: currentMonth) { newValue in
            
            // updating Month...
            currentDate = getCurrentMonth()
        }
        .onAppear {
            
            let user = Auth.auth().currentUser
            if let user = user {
                let email = user.email ?? "error"
                let userEmail = email.replacingOccurrences(of: ".", with: "*")
                
                ref.child(userEmail).observe(.value) {
                    snapshot in
                    
                    guard let snapData = snapshot.value as? [String: String] else {return}
                    
                    let data = try! JSONSerialization.data(withJSONObject: Array(snapData.values), options: [])
                    print("1, \(snapData.values)")
                    print("2, \(snapData.values.count)")
                    
                    snapData.values.forEach {
                        let singleTask = $0.data(using: .utf8)!
                        do {
                            let finalData = try? JSONDecoder().decode(TaskMetaData.self,
                                                                      from: singleTask)
                            tasks.append(finalData!)
                            print("value is \(finalData?.task.first?.time)")
                            print("value is \(finalData?.task.first?.title)")
                        } catch {
                            print("encoding error")
                        }
                        
                    }
                    
                    
                }
                
            }
            
            //            tasks.append(TaskMetaData(task: [
            //                Task(title: "힘내요!")
            //            ], taskDate: getSampleDate(offset: 2)))
        }
    }
    
    
    @ViewBuilder
    func CardView(value: DateValue) -> some View {
        VStack {
            if value.day != -1 {
                
                if let task = tasks.first(where: { task in
                    return isSameDay(date1: task.taskDate, date2: value.date)
                }) {
                    Text("\(value.day)")
                        .font(.title3.bold())
                        .foregroundColor(isSameDay(date1: task.taskDate, date2: currentDate) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Circle()
                        .fill(isSameDay(date1: task.taskDate, date2: currentDate) ? .white : Color("Green"))
                        .frame(width: 8,height: 8)
                }
                else{
                    
                    Text("\(value.day)")
                        .font(.title3.bold())
                        .foregroundColor(isSameDay(date1: value.date, date2: currentDate) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical,9)
        .frame(height: 60,alignment: .top)
    }
    
    // checking dates...
    func isSameDay(date1: Date, date2: Date) -> Bool{
        let calendar = Calendar.current
        
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    // extrating Year And Month for display...
    func extraStringTime(attendDate: Date) -> String {

        let date = DateFormatter()
        date.dateFormat = "a HH시 mm분"
        let todayDate = date.string(from: attendDate)

        return todayDate
    }
    
    func extraDate() -> [String] {
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate) - 1
        let year = calendar.component(.year, from: currentDate)
        
        return ["\(year)",calendar.monthSymbols[month]]
    }
    
    func getCurrentMonth()->Date{
        
        let calendar = Calendar.current
        
        // Getting Current Month Date....
        guard let currentMonth = calendar.date(byAdding: .month, value: self.currentMonth, to: Date()) else{
            return Date()
        }
        
        return currentMonth
    }
    
    func extractDate() -> [DateValue]{
        
        let calendar = Calendar.current
        
        // Getting Current Month Date....
        let currentMonth = getCurrentMonth()
        
        var days = currentMonth.getAllDates().compactMap { date -> DateValue in
            
            // getting day...
            let day = calendar.component(.day, from: date)
            
            return DateValue(day: day, date: date)
        }
        
        // adding offset days to get exact week day...
        let firstWeekday = calendar.component(.weekday, from: days.first!.date)
        
        for _ in 0..<firstWeekday - 1{
            days.insert(DateValue(day: -1, date: Date()), at: 0)
        }
        
        return days
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Extending Date to get Current Month Dates...
extension Date {
    
    func getAllDates()->[Date] {
        
        let calendar = Calendar.current
        
        // getting start Date...
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
        
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        // getting date...
        return range.compactMap { day -> Date in
            
            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
}

// Date Value Model...
struct DateValue: Identifiable{
    var id = UUID().uuidString
    var day: Int
    var date: Date
}

// Task Model and Sample Tasks...
// Array of Tasks...
struct Task: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var time: Date = Date()
}

// Total Task Meta View...
struct TaskMetaData: Identifiable, Codable {
    var id = UUID().uuidString
    var task: [Task]
    var taskDate: Date
}



// sample Date for Testing...
//func getSampleDate(offset: Int)->Date {
//    let calender = Calendar.current
//
//    let date = calender.date(byAdding: .day, value: offset, to: Date())
//
//    return date ?? Date()
//}

// Sample Tasks...

//        TaskMetaData(task: [
//            Task(title: "힘내요!")
//        ], taskDate: getSampleDate(offset: 1)),
//
//        TaskMetaData(task: [
//            Task(title: "오늘도 와주셨군요!")
//        ], taskDate: getSampleDate(offset: 3)),
//
//        TaskMetaData(task: [
//            Task(title: "고마워요!")
//        ], taskDate: getSampleDate(offset: 6)),
//        TaskMetaData(task: [
//
//            Task(title: "대단해요")
//        ], taskDate: getSampleDate(offset: 11)),
//
//        TaskMetaData(task: [
//            Task(title: "노력이 쌓이네요")
//        ], taskDate: getSampleDate(offset: -1)),
//
//        TaskMetaData(task: [
//            Task(title: "기다리고 있었습니다 😂")
//        ], taskDate: getSampleDate(offset: -3)),
//
//        TaskMetaData(task: [
//            Task(title: "내일도 오실꺼죠..?")
//        ], taskDate: getSampleDate(offset: -5)),
