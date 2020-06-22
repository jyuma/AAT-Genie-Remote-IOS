//
//  ImagePickerViewController.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-21.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import Foundation
import UIKit

class ImagePickerViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!

    var imagePicker: ImagePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    @IBAction func showImagePicker(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
}

extension ImagePickerViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.imageView.image = image
    }
}
