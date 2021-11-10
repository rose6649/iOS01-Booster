//
//  MileStonePhotoViewController.swift
//  Booster
//
//  Created by mong on 2021/11/08.
//

import UIKit

protocol MileStonePhotoViewControllerDelegate: AnyObject {
    func delete(mileStone: MileStone)
}

class MileStonePhotoViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: MileStonePhotoViewControllerDelegate?
    private var mileStonePhotoViewModel: MileStonePhotoViewModel = MileStonePhotoViewModel(mileStone: MileStone())

    private lazy var mileStonePhotoImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: view.frame.width,
                                                  height: view.frame.height))
        imageView.image = UIImage(data: mileStonePhotoViewModel.mileStone.imageData ?? Data())?.withTintColor(.white)
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()
    private lazy var deleteButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: 50,
                                            height: 20))
        button.setTitleColor(.systemIndigo, for: .normal)
        button.setTitle("delete", for: .normal)
        button.addTarget(self, action: #selector(didTapDeleteButton(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Init
    init(viewModel: MileStonePhotoViewModel) {
        super.init(nibName: nil, bundle: nil)

        self.mileStonePhotoViewModel = viewModel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycles
    override func viewDidLoad() {
        view.backgroundColor = UIColor.boosterBackground
        view.addSubview(mileStonePhotoImageView)
        view.addSubview(deleteButton)

        layoutConfig()
    }

    // MARK: - @objc
    @objc private func didTapDeleteButton(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
        delegate?.delete(mileStone: mileStonePhotoViewModel.mileStone)
    }

    // MARK: - functions
    private func layoutConfig() {
        view.addConstraints([
            deleteButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
