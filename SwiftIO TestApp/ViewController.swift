//
//  ViewController.swift
//  SwiftIO TestApp
//
//  Created by Jonathan Wight on 8/23/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import UIKit

import SwiftIO

class ViewController: UIViewController {

    override func viewDidLoad() {
//        let address_1 = try! Address(address: "10.1.1.1:1234", mappedIPV4: false)
//        print(address_1)

        let address_2 = try! Address(address: "10.1.1.1:80", mappedIPV4: false)
        print(address_2)
    }


}

