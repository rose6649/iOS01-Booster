//
//  ChangeGoalViewController.swift
//  Booster
//
//  Created by mong on 2021/11/17.
//

import UIKit

class ChangeGoalViewController: UIViewController, BaseViewControllerTemplate {
    // MARK: - Enum

    // MARK: - @IBOutlet
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stepsTextField: UITextField!

    // MARK: - Properties
    var viewModel: GoalViewModel?
    var steps: Int = 10000

    // MARK: - Init

    // MARK: - Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        naivgationBarConfigure()
        UIConfigure()

        stepsTextField.becomeFirstResponder()
    }

    // MARK: - @IBActions
    @IBAction func backButtonDidTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func saveButtonDidTap(_ sender: Any) {
        
    }
    
    // MARK: - @objc

    // MARK: - Functions
    private func naivgationBarConfigure() {
        navigationController?.title = "목표 바꾸기"
    }

    private func UIConfigure() {
        titleLabel.text = "현재 목표는\n\(steps) 걸음이에요\n얼마나 바꿔볼까요?"

        let border = CALayer()
        border.frame = CGRect(x: 0, y: stepsTextField.frame.size.height - 1, width: stepsTextField.frame.size.width, height: 1)
        border.backgroundColor = UIColor.boosterOrange.cgColor
        stepsTextField.layer.addSublayer(border)
        stepsTextField.layer.masksToBounds = true
    }
}
