//
//  Playlist.swift
//  破音万里
//
//  Created by Purchas on 2016/11/9.
//  Copyright © 2016年 Purchas. All rights reserved.
//

import UIKit

class Playlist: NSObject {
	var ID: Int = 0
	var title: String = ""
	var cover: String = ""
	
	func setupMappingReplaceProperty() -> [String : String] {
		return ["ID": "id"]
	}
}


