//
//  ChangeGoalViewController.swift
//  Booster
//
//  Created by mong on 2021/11/17.
//

import UIKit

class ChangeGoalViewController: UIViewController, BaseViewControllerTemplate {
    // MARK: - @IBOutlet
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var stepsTextField: UITextField!

    // MARK: - Properties
    var viewModel: GoalViewModel?
    private var steps: Int = 10000

    // MARK: - Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        stepsTextField.delegate = self

        navigationBarTitleConfigure()
        configureUI()
        placeholderOfGoalTextField(steps: steps)
    }

    // MARK: - @IBActions
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        if changeGoalValidator() {

        } else {
            let alert = UIAlertController.simpleAlert(title: "변경 실패", message: "걸음 수가 빈칸 이거나 0인지 확인해주세요")
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Functions
    private func navigationBarTitleConfigure() {
        title = "목표 바꾸기"
    }

    private func configureUI() {
        titleLabel.text = "현재 목표는\n\(steps) 걸음이에요\n얼마나 바꿔볼까요?"

        let border = CALayer()
        border.frame = CGRect(x: 0, y: stepsTextField.frame.size.height - 1, width: stepsTextField.frame.size.width, height: 1)
        border.backgroundColor = UIColor.boosterOrange.cgColor
        stepsTextField.layer.addSublayer(border)
        stepsTextField.layer.masksToBounds = true
    }

    private func placeholderOfGoalTextField(steps: Int) {
        stepsTextField.clearsOnBeginEditing = true
        stepsTextField.textColor = .boosterGray
        stepsTextField.text = attributedTextOfcurrentGoal(steps: steps)
    }

    private func attributedTextOfcurrentGoal(steps: Int) -> String {
        let attributedString = NSAttributedString(string: "\(steps)", attributes: [.foregroundColor: UIColor.boosterGray])

        return attributedString.string
    }

    private func changeGoalValidator() -> Bool {
        guard let stepsText = stepsTextField.text,
              let steps = Int(stepsText)
        else { return false }

        if steps == 0 { return false }

        return true
    }
}

// MARK: - UITextFieldDelegate
extension ChangeGoalViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        stepsTextField.textColor = .boosterOrange

        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text
        else { return true }

        let maxLength = 5
        let length = text.count + string.count - range.length

        return length <= maxLength
    }
}
