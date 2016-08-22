//
//  GlobalData.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import MBProgressHUD

var iPhoneType = ""
var hud = MBProgressHUD()
var isDownloadingSetupData = true
var allSongs = [SongModel]()
var allCategories = [String]()
let SWEDISH = NSLocale(localeIdentifier: "sv")
typealias DownloadComplete = () -> ()