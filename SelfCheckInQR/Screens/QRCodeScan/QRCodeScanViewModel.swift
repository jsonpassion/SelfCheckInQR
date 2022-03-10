//
//  QRCodeScanViewModel.swift
//  SelfCheckInQR
//
//  Created by hyunho lee on 2022/03/10.
//

import SwiftUI

final class QRCodeScanViewModel: ObservableObject {
    
    @Published var scannedCode = ""
    @Published var alertItem: AlertItem?
    
    var statusText: String {
        if scannedCode.isEmpty {
            return "아직 스캔되지 않았습니다."
        } else {
            if scannedCode == "leeo" {
                saveCheckInHistory()
                return "출석되었습니다."
            } else {
                return "\(scannedCode)는 올바른 값이 아닙니다."
            }
        }
    }
    
    var statusTextColor: Color {
        if scannedCode.isEmpty {
            return .red
        } else {
            if scannedCode == "leeo" {
                return .green
            } else {
                return .red
            }
        }
    }
    
    private func saveCheckInHistory() {
        // TODO: 어딘가에 저장 해야함
        print("출석 이력이 저장되었습니다")
    }
}
