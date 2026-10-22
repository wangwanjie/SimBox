#!/usr/bin/env swift
//
// 输出 SimBox 当前弹出菜单窗口（layer 101）的外接矩形，格式 "x,y,w,h"，供 screencapture -R 使用。
// 传入 --first 时只输出第一个（主菜单）窗口。
//

import CoreGraphics
import Foundation

let firstOnly = CommandLine.arguments.contains("--first")
let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let rects = infos
    .filter { ($0[kCGWindowOwnerName as String] as? String) == "SimBox" && ($0[kCGWindowLayer as String] as? Int) == 101 }
    .compactMap { info -> CGRect? in
        guard let bounds = info[kCGWindowBounds as String] as? NSDictionary else {
            return nil
        }
        return CGRect(dictionaryRepresentation: bounds)
    }
    .sorted { $0.minX < $1.minX }

guard var union = rects.first else {
    exit(1)
}

if !firstOnly {
    for rect in rects.dropFirst() {
        union = union.union(rect)
    }
}

print("\(Int(union.minX)),\(Int(union.minY)),\(Int(union.width)),\(Int(union.height))")
