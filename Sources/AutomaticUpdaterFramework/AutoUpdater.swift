//
//  AutoUpdater.swift
//  Coproman
//
//  Created by Jaccoud Damien on 24.03.24.
//

#if os(macOS)

#if canImport(SwiftUI)
import SwiftUI
#endif
import AppKit

public class AutoUpdater : Host {

    
    ///Shared instance of the updater
    static public var shared: AutoUpdater = {
        return AutoUpdater()
    }()
    
    #if targetEnvironment(macCatalyst)
    var rootViewController:UIViewController?
    #endif
    
//    One should not be able to instantiate this class! Always use the AutoUpdater.shared !!!
    private override init() {
        super.init()
    }
    
    #if canImport(SwiftUI)
    ///The description of the new version
    fileprivate var newVersion: VersionDescription?
    
    #else
    
    #endif
    
    /**
     Check if a new update is available
     
     If a new update is available, informs the user automatically
     */
    public func checkForUpdate() {
        Task {
            await self.askHostForAnUpdate()
        }
    }
    /**
     Ask the server if an update is available
     */
    private func askHostForAnUpdate() async {
        print("récupération des versions")
        let post = "isUpdate=true&app=\(Host.bundleIdentifer)&currentVersion=\(Host.currentVersion)&getLatest=true"
        guard let url = URL(string: Host.link) else {
            print("Invalid url")
            return
        }
        var requete = URLRequest(url:url)
        requete.httpMethod = "POST"
        requete.httpBody = post.data(using: .utf8)
        
        
        do {
            let (data, _ ) = try await URLSession.shared.data(for: requete)
            do {
                let response = try JSONDecoder().decode(UpdateResult.self, from: data)
                //                        print(response)
                if response.error == nil {
                    if response.recommanded != nil {
                        self.launchUpdateProcess(for: response.recommanded!)
                    }
                } else {
                    print("Error on server side : \(String(describing: response.error))")
                }
            } catch let e as NSError {
                print("Impossible to decode the data: \(e)")
                print("Decoded data: \(String(describing: try? JSONSerialization.jsonObject(with: data) as? [String:Any]))")
            }
        } catch let e as NSError {
            print("Error to retrieve data : \(e)")
        }
    }
    
    /**
     Indicate if an update should be performed
     
     - parameter serverVersion: The version returned from the server
     **/
    private func isUpdate(serverVersion:ProgramVersion) -> Bool {
        print(serverVersion, AutoUpdater.currentVersion, serverVersion > AutoUpdater.currentVersion)
        return serverVersion > AutoUpdater.currentVersion
    }
    
    /**
     Display the alert informing that a new version is available
     */
    private func launchUpdateProcess(for version:VersionDescription) {
        #if canImport(SwiftUI)
//        Set the new version and indicate that the object changed. This will notify the UpdaterAlert ViewModifier that it needs to check if a new update is available
        DispatchQueue.main.async {
            self.newVersion = version
            self.objectWillChange.send()
        }
        #elseif targetEnvironment(macCatalyst)
        if let viewController = self.rootViewController {
            DispatchQueue.main.async {
                let alert = CustomAlert()
                alert.delegate = self
                alert.alertTitle = "A new update is available. Do you want to install it ?"
                alert.message = "You are using version \(AutoUpdater.currentVersion). Version \(version) is now available"
//                alert.modalPresentationStyle = .fullScreen
                viewController.present(alert, animated: false)
                print("View presented")
            }
        } else {
            print("Impossible to present the view")
        }
        #else
        fatalError("Unimplemented updater presentation")
        #endif
    }
    
    /**
     Test if an update is necessary
     
     - returns: `true` if the an update is available
     */
    public func shouldUpdate() -> Bool {
        if let versionDescription = self.newVersion {
            return self.isUpdate(serverVersion: versionDescription.version)
        }
        return false
    }
    
    /**
     Launch the Updater app and send the necessary informations to it
     */
    func installUpdate() {
        print("Installing update")
        guard let url:URL = Bundle.main.url(forResource: Host.updaterName, withExtension: ".app") else {
            print("Impossible to find url of updater")
            return
        }
        guard let versionDescription: VersionDescription = self.newVersion else { return}
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                print("App opend")
                exit(0)//On termine l'application... Pas très propre, mais ça fait le job
            }  else {
                print("Impossible to open app..")
            }
        }
        #else
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.environment = [Host.urlEnvironmentKey:versionDescription.url.absoluteString]
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            if error == nil {
                print("App opened...")
//                exit(0)//Terminate the application. This is not clean, but it does work...
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            } else {
                print("Impossible to open the app...")
            }
        }
        #endif
    }
    
}

#if targetEnvironment(macCatalyst)
extension AutoUpdater : CustomAlertDelegate {
    func didUserChoose(_ alert: CustomAlert, userAccepted: Bool) {
        if userAccepted {
            self.installUpdate()
        }
    }
}

class CustomAlert : UIViewController {
    let currentVersion = "1.0"
    let version = "1.1"
    
    var alertTitle:String?
    var message:String?
    
    var delegate : CustomAlertDelegate?
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.clear
        self.view.isOpaque = false
    }
    override func viewDidAppear(_ animated: Bool) {
        let alert = UIAlertController(title: self.alertTitle, message: self.message, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
            self.delegate?.didUserChoose(self, userAccepted: false)
            self.dismiss(animated: false)
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
//            self.installUpdate()
            self.delegate?.didUserChoose(self, userAccepted: true)
            print("Yes!!!")
            self.dismiss(animated: false)
        }))
        self.present(alert, animated: true)
    }
}

protocol CustomAlertDelegate {
    func didUserChoose(_ alert: CustomAlert, userAccepted:Bool)
}
#endif


///Add conformance to [ObservalbeObject](doc://com.apple.documentation/18ulm41?language=swift&usr=true) object
extension AutoUpdater : ObservableObject {
    
}

/**
 SwitfUI ViewModifier to add in the view where the update check is perform.
 
 This modifier can be added anywhere in the  view Hierarchy. It will automatically check for updates and reacts accordingly.
 */
public struct UpdaterAlert : ViewModifier {
    
    let autoUpdater: AutoUpdater = AutoUpdater.shared
    
    ///Indicate whether the view is presented or not
    @State var isUpdateAvailable: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .onReceive(self.autoUpdater.objectWillChange, perform: { output in
                self.isUpdateAvailable = self.autoUpdater.shouldUpdate()
            })
            .alert("A new update is available. Do you want to install it?", isPresented: self.$isUpdateAvailable, actions: {
                Button("Yes", role: .none, action: {
                    self.autoUpdater.installUpdate()
                })
                Button("No", role: .cancel, action: {
                    print("No updater...")
                })
            }, message: {
                Text("You are using version \(String(describing: AutoUpdater.currentVersion)). Version \(String(describing: self.autoUpdater.newVersion?.version ?? AutoUpdater.currentVersion)) is now available")
            })
            .onAppear() {
                self.autoUpdater.checkForUpdate()
            }
    }
}

extension View {
    #warning("Can even go further in how much this modifier is autonomous: The binding  can  be handled internally and become a @State, the autoUpdater is simply the AutoUpdater.shared variable...")
    /**
     Add the capabilities to check for updates to your view
     
     Each view having this modifier will check independantly for an update. It is recommanded to place it at the root of a view hierarchy. See the description in ``AutoUpdater`` for examples.
     */
    public func updaterAlert(/*autoUpdater: AutoUpdater, isUpdateAvailable: Binding<Bool>*/) -> some View {
        modifier(UpdaterAlert(/*autoUpdater: autoUpdater, isUpdateAvailable: isUpdateAvailable*/))
    }
}
#endif
