#!/usr/bin/env swift
//
// 把鼠标平滑移动到指定屏幕坐标，用于展开菜单的子菜单。用法: hover.swift X Y
//

import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 3, let x = Double(CommandLine.arguments[1]), let y = Double(CommandLine.arguments[2]) else {
    exit(1)
}

for step in 0...10 {
    let point = CGPoint(x: x - 40 + Double(step) * 4, y: y)
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?
        .post(tap: .cghidEventTap)
    usleep(30000)
}
