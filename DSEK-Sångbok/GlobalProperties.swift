//
//  GlobalData.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import MBProgressHUD

var realm = try! Realm()
var iPhoneType = ""
var hud = MBProgressHUD()
var isDownloadingSetupData = true