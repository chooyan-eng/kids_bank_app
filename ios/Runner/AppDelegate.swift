import Flutter
import PhotosUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pendingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ImagePickerPlugin")
    let channel = FlutterMethodChannel(
      name: "com.kids_bank_app/image_picker",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "pickImage" {
        self?.pendingResult = result
        self?.presentPhotoPicker()
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func presentPhotoPicker() {
    var config = PHPickerConfiguration()
    config.filter = .images
    config.selectionLimit = 1

    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self

    guard
      let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
      let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else {
      pendingResult?(nil)
      pendingResult = nil
      return
    }
    rootVC.present(picker, animated: true)
  }
}

extension AppDelegate: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard
      let itemProvider = results.first?.itemProvider,
      itemProvider.canLoadObject(ofClass: UIImage.self)
    else {
      pendingResult?(nil)
      pendingResult = nil
      return
    }

    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
      DispatchQueue.main.async {
        if let image = reading as? UIImage,
          let data = image.jpegData(compressionQuality: 0.9)
        {
          self?.pendingResult?(FlutterStandardTypedData(bytes: data))
        } else {
          self?.pendingResult?(nil)
        }
        self?.pendingResult = nil
      }
    }
  }
}
