import UIKit
import MapKit
import CoreMotion

class TrackingProgressViewController: UIViewController {
    enum NibName: String {
        case photoAnnotationView = "PhotoAnnotationView"
    }

    enum Identifier {
        enum Annotation: String {
            case milestone = "milestone"
        }
    }

    enum Color {
        static let orange = UIColor.init(red: 1.0, green: 0.332, blue: 0.0, alpha: 1)
    }

    enum Image {
        static let pause = UIImage(systemName: "pause")
        static let camera = UIImage(systemName: "camera")
        static let stop = UIImage(systemName: "stop")
        static let play = UIImage(systemName: "play")
        static let pencil = UIImage(systemName: "pencil")
    }

    weak var delegate: TrackingProgressDelegate?
    private var lastestTime: Int = 0
    private var viewModel: TrackingProgressViewModel = TrackingProgressViewModel()
    private var pedometerDate = Date()
    private var timerDate = Date()
    private var timer = Timer()
    private var manager: CLLocationManager = CLLocationManager()
    private lazy var imagePickerController: UIImagePickerController = {
       let pickerController = UIImagePickerController()
        pickerController.sourceType = .camera
        pickerController.allowsEditing = true
        pickerController.cameraDevice = .rear
        pickerController.cameraCaptureMode = .photo
        pickerController.delegate = self
        return pickerController
    }()
    private lazy var titleTextField: UITextField = {
        let textField = UITextField(frame: self.view.frame)
        let title = "제목"
        textField.font = .notoSansKR(.medium, 25)
        textField.textColor = .white
        textField.attributedPlaceholder = .makeAttributedString(text: title, font: .notoSansKR(.medium, 25), color: .lightGray)
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    private lazy var contentTextView: UITextView = {
        let textView = UITextView()
        let emptyText = "오늘 산책은 어땠나요?"
        textView.backgroundColor = .clear
        textView.font = .notoSansKR(.light, 17)
        textView.text = emptyText
        textView.textColor = .lightGray
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        return textView
    }()
    private let pedometer = CMPedometer()

    @IBOutlet weak var mapView: TrackingMapView!
    @IBOutlet weak var pedometerLabel: UILabel!
    @IBOutlet weak var kcalLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var pedometerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var pedometerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var kcalTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var distanceTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNotifications()
        configure()
        locationAuth()
        delegate?.location(mapView: mapView)
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func bind() {
        viewModel.trackingModel.bind { [weak self] model in
            guard let self = self else {
                return
            }
            self.updatePedometer()
            self.configure(model: model)
        }

        viewModel.milestones.bind({ [weak self] milestones in
            guard let milestone = milestones.last,
                  let latitude = milestone.coordinate.latitude,
                  let longitude = milestone.coordinate.longitude
            else { return }
            self?.mapView.addMileStoneAnnotation(latitude: latitude, longitude: longitude)
        })
    }

    private func configure() {
        let radius: CGFloat = 50
        leftButton.layer.borderWidth = 1
        leftButton.layer.borderColor = UIColor.black.cgColor
        leftButton.layer.cornerRadius = radius
        rightButton.layer.cornerRadius = radius
        pedometerLabel.font = .bazaronite(size: 60)
        pedometerLabel.textColor = .black

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(trackingTimer), userInfo: nil, repeats: true)
        [mapView, kcalLabel, timeLabel, distanceLabel, pedometerLabel, rightButton].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        mapView.delegate = self
        manager.delegate = self
    }

    private func configure(model: TrackingModel) {
        let timeContent = makeTimerText(time: model.seconds)
        let kcalContent = "\(model.calories)\n"
        let distanceContent = "\(String.init(format: "%.1f", model.distance/1000))\n"
        let stepsTitle = "\(viewModel.state == .end ? " steps" : "")"
        let kcalTitle = "kcal"
        let timeTitle = "time"
        let distanceTitle = "km"
        let color: UIColor = viewModel.state == .start ? .black : .white

        pedometerLabel.attributedText = makeAttributedText(content: "\(model.steps)",
                                                           title: stepsTitle,
                                                           contentFont: .bazaronite(size: 60),
                                                           titleFont: .notoSansKR(.regular, 20),
                                                           color: Color.orange)
        kcalLabel.attributedText = makeAttributedText(content: kcalContent, title: kcalTitle, color: color)
        timeLabel.attributedText = makeAttributedText(content: timeContent, title: timeTitle, color: color)
        distanceLabel.attributedText = makeAttributedText(content: distanceContent, title: distanceTitle, color: color)
    }

    private func update() {
        let isStart: Bool = viewModel.state == .start
        [distanceLabel, timeLabel, kcalLabel].forEach {
            $0?.textColor = isStart ? .black : .white
        }

        infoView.backgroundColor = isStart ? Color.orange : .black
        rightButton.backgroundColor = isStart ? .black : Color.orange
        leftButton.backgroundColor = isStart ? Color.orange : .black
        leftButton.layer.borderColor = isStart ? UIColor.black.cgColor : Color.orange.cgColor
        leftButton.tintColor = isStart ? .black : Color.orange
        rightButton.tintColor = isStart ? Color.orange : .black
        rightButton.setImage(isStart ? Image.pause : Image.play, for: .normal)
        leftButton.setImage(isStart ? Image.camera : Image.stop, for: .normal)
        timerDate = isStart ? Date() : timerDate

        switch isStart {
        case true:
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(trackingTimer), userInfo: nil, repeats: true)
            pedometerDate = Date()
            locationAuth()
        case false:
            lastestTime = viewModel.trackingModel.value.seconds
            viewModel.update(seconds: lastestTime)
            timer.invalidate()
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            pedometer.stopUpdates()
        }
    }

    private func configureWrite() {
        infoView.addSubview(titleTextField)
        infoView.addSubview(contentTextView)
        titleTextField.topAnchor.constraint(equalTo: kcalLabel.bottomAnchor, constant: 20).isActive = true
        titleTextField.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20).isActive = true
        titleTextField.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20).isActive = true
        contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20).isActive = true
        contentTextView.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -10).isActive = true
        contentTextView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20).isActive = true
        contentTextView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20).isActive = true
    }

    private func locationAuth() {
        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestWhenInUseAuthorization()
            DispatchQueue.main.async { [weak self] in
                self?.manager.startUpdatingLocation()
                self?.manager.startMonitoringSignificantLocationChanges()
            }
            updatePedometer()
            manager.distanceFilter = 1
        }
    }

    private func updatePedometer() {
        pedometer.startUpdates(from: pedometerDate) { [weak self] data, _ in
            guard let self = self, let data = data else { return }

            DispatchQueue.main.async {
                self.pedometer.stopUpdates()
                self.pedometerDate = Date()
                self.viewModel.update(steps: data.numberOfSteps.intValue)
            }
        }
    }

    private func stopAnimation() {
        self.leftButton.isHidden = true
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self, let content = self.pedometerLabel.text else {
                return
            }
            let title = " steps"
            self.rightButtonWidthConstraint.constant = 70
            self.rightButtonHeightConstraint.constant = 70
            self.rightButton.layer.cornerRadius = 35
            self.rightButtonTrailingConstraint.constant = 25
            self.rightButtonBottomConstraint.constant = 25
            self.pedometerLabel.textColor = Color.orange
            self.mapViewBottomConstraint.constant = self.view.frame.maxY - 290
            self.pedometerTrailingConstraint.constant = self.view.frame.maxX - 230
            self.pedometerTopConstraint.constant = 20
            [self.timeTopConstraint, self.kcalTopConstraint, self.distanceTopConstraint].forEach {
                $0.constant = 130
            }
            self.rightButton.setImage(Image.pencil, for: .normal)
            self.pedometerLabel.attributedText = self.makeAttributedText(content: content,
                                                                         title: title,
                                                                         contentFont: .bazaronite(size: 60),
                                                                         titleFont: .notoSansKR(.regular, 20),
                                                                         color: Color.orange)
            self.view.layoutIfNeeded()
            self.infoView.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.configureWrite()
            self.infoView.bringSubviewToFront(self.rightButton)
        })
    }

    private func makeTimerText(time: Int) -> String {
        let seconds = time % 60
        let minutes = (time / 60) % 60
        var text = ""
        text += "\(minutes < 10 ? "0\(minutes)'" : "\(minutes)'")"
        text += "\(seconds < 10 ? "0\(seconds)\"\n" : "\(seconds)\"\n")"
        return text
    }

    private func makeAttributedText(content: String, title: String, contentFont: UIFont = .bazaronite(size: 30), titleFont: UIFont = .notoSansKR(.light, 15), color: UIColor = .black) -> NSMutableAttributedString {
        let mutableString = NSMutableAttributedString()

        let contentText: NSAttributedString = .makeAttributedString(text: content, font: contentFont, color: color)
        let titleText: NSAttributedString = .makeAttributedString(text: title, font: titleFont, color: color)

        [contentText, titleText].forEach {
            mutableString.append($0)
        }

        return mutableString
    }

    @IBAction func leftTouchUp(_ sender: UIButton) {
        switch viewModel.state {
        case .start:
            present(imagePickerController, animated: true)
        default:
            viewModel.recordEnd()
            stopAnimation()
        }
    }

    @IBAction func rightTouchUp(_ sender: Any) {
        switch viewModel.state {
        case .end:
            viewModel.save { message in
                let title = "저장 여부"
                let alert = UIAlertController.simpleAlert(title: title, message: message)
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            }
        default:
            viewModel.toggle()
            update()
        }
    }

    @objc
    private func trackingTimer() {
        let time = -Int(timerDate.timeIntervalSinceNow) + lastestTime
        let calroies = Int(60 / 15 * 0.9 * Double((time / 60) % 60))
        viewModel.update(seconds: time)
        viewModel.update(calroies: calroies)
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            view.frame.origin.y == 0 {
            view.frame.origin.y = -keyboardSize.height
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
            view.setNeedsLayout()
        }
    }
}

extension TrackingProgressViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        let currentCoordinate = currentLocation.coordinate
        guard let latestCoordinate = viewModel.latestCoordinate(),
              let prevLatitude = latestCoordinate.latitude,
              let prevLongitude = latestCoordinate.longitude
        else {
            viewModel.append(coordinate: Coordinate(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude))
            return
        }
        let prevCoordinate = CLLocationCoordinate2D(latitude: prevLatitude, longitude: prevLongitude)
        let latestLocation = CLLocation(latitude: prevLatitude, longitude: prevLongitude)

        mapView.updateUserLocationOverlay(location: currentLocation)
        if viewModel.state == .start { mapView.drawPath(from: prevCoordinate, to: currentCoordinate) }

        viewModel.update(distance: latestLocation.distance(from: currentLocation))
        viewModel.append(coordinate: Coordinate(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}

extension TrackingProgressViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = CircleRenderer(circle: overlay)

            return circleRenderer
        }

        if let polyLine = overlay as? MKPolyline {
            let polyLineRenderer = MKPolylineRenderer(polyline: polyLine)
            polyLineRenderer.strokeColor = UIColor(red: 255/255, green: 92/255, blue: 0/255, alpha: 1)
            polyLineRenderer.lineWidth = 8

            return polyLineRenderer
        }

        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Identifier.Annotation.milestone.rawValue)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: Identifier.Annotation.milestone.rawValue)
            annotationView!.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        guard let customView = UINib(nibName: NibName.photoAnnotationView.rawValue, bundle: nil).instantiate(withOwner: self, options: nil).first as? PhotoAnnotationView,
              let mileStone = viewModel.milestones.value.last
        else { return nil }

        customView.photoImageView.image = UIImage(data: mileStone.imageData)
        customView.photoImageView.backgroundColor = .white
        annotationView?.addSubview(customView)
        annotationView?.centerOffset = CGPoint(x: -customView.frame.width / 2.0, y: -customView.frame.height)

        return annotationView
    }
}

extension TrackingProgressViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let currentCoordinate = viewModel.latestCoordinate(),
                  let currentLatitude = currentCoordinate.latitude,
                  let currentLogitude = currentCoordinate.longitude,
                  let imageData = image.pngData()
            else { return }
            let mileStone = MileStone(latitude: currentLatitude, longitude: currentLogitude, imageData: imageData)
            viewModel.append(milestone: mileStone)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension TrackingProgressViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = .white
        }
        rightButton.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            let emptyText = "오늘 산책은 어땠나요?"
            textView.text = emptyText
            textView.textColor = .lightGray
        }
        rightButton.isHidden = false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        viewModel.write(content: textView.text)
    }
}

extension TrackingProgressViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let title = textField.text else {
            return
        }
        viewModel.write(title: title)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        rightButton.isHidden = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        rightButton.isHidden = false
    }
}
