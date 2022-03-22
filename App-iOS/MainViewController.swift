import UIKit
import NetworkExtension
import os.log

class MainViewController: UITableViewController {

    let log = OSLog(subsystem: "org.pluslab.SimpleTunnel", category: "app")

    @IBOutlet private var statusLabel: UILabel!
    private var connection: NWConnection!
    
    private var status: String = "" {
        didSet {
            self.statusLabel.text = self.status
        }
    }
    
    
    @IBOutlet var ReceiveData: UITableViewCell!
    
    
    private var Receive: String = "" {
        didSet {
            self.ReceiveData.textLabel!.text = self.Receive
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0): break
        case (0, 1): self.configurePacketTunnel()
        case (0, 2): self.connectPacketTunnel()
        case (0, 3): break
        default: fatalError()
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Configure
    
    @IBOutlet private var sendTextbox: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        sendTextbox.text = "Hello,VirtualInterface!"
    }
    
    
    
    private func configurePacketTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { managersQ, errorQ in
            precondition(Thread.isMainThread)
            if let nsError = errorQ as NSError? {
                os_log(.debug, log: self.log, "did not load configurations, error: %{public}@ / %zd", nsError.domain, nsError.code)
                self.status = "Error loading configurations."
                return
            }
            let managers = managersQ ?? []
            os_log(.debug, log: self.log, "did load configurations, count: %zd", managers.count)
            
            let managerQ = managers.first(where: self.isOurManager(_:))
            let manager: NETunnelProviderManager
            if let m = managerQ {
                os_log(.debug, log: self.log, "did find configuration, updating")
                manager = m
            } else {
                os_log(.debug, log: self.log, "did not find configuration, adding")
                manager = NETunnelProviderManager()
            }
            self.storeConfiguration(in: manager)
            manager.saveToPreferences { errorQ in
                if let nsError = errorQ as NSError? {
                    os_log(.debug, log: self.log, "did not save configuration, error: %{public}@ / %zd", nsError.domain, nsError.code)
                    self.status = "Error saving configuration."
                    return
                }
                os_log(.debug, log: self.log, "did save configuration")
                self.status = "Configuration saved."
            }
        }
    }
    
    private func isOurManager(_ manager: NETunnelProviderManager) -> Bool {
        guard
            let proto = manager.protocolConfiguration,
            let tunnelProto = proto as? NETunnelProviderProtocol
        else {
            return false
        }
        return tunnelProto.providerBundleIdentifier == "org.pluslab.SimpleTunnel.PacketTunnel"
    }

    private func storeConfiguration(in manager: NETunnelProviderManager) {
        let proto = (manager.protocolConfiguration as? NETunnelProviderProtocol) ?? NETunnelProviderProtocol()

        // `NEVPNProtocol` properties…
        //
        // You have to configure a server address.
        proto.serverAddress = "10.0.3.90"
        // All the other `NEVPNProtocol` properties are optional.

        // `NETunnelProviderProtocol` properties…
        //
        // Use `providerConfiguration` to pass configuration parameters to your
        // tunnel provider.
        //
        // `providerBundleIdentifier` is important on macOS but we set it here anyway.
        proto.providerBundleIdentifier = "org.pluslab.SimpleTunnel.PacketTunnel"
        
        manager.protocolConfiguration = proto
        manager.isEnabled = true
        manager.localizedDescription = "PacketTunnelTestbed"
    }

    // MARK: - Connect
    
    private func connectPacketTunnel() {
        os_log(.debug, log: self.log, "will load configurations")
        NETunnelProviderManager.loadAllFromPreferences { managersQ, errorQ in
            precondition(Thread.isMainThread)
            if let nsError = errorQ as NSError? {
                os_log(.debug, log: self.log, "did not load configurations, error: %{public}@ / %zd", nsError.domain, nsError.code)
                self.status = "Error loading configurations."
                return
            }
            let managers = managersQ ?? []
            os_log(.debug, log: self.log, "did load configurations, count: %zd", managers.count)
            
            guard let manager = managers.first(where: self.isOurManager(_:)) else {
                os_log(.debug, log: self.log, "no appropriate manager")
                self.status = "Not configured."
                return
            }
            do {
                try manager.connection.startVPNTunnel()
                os_log(.debug, log: self.log, "did start connection")
                self.status = "Did start connection."
                self.connectVirtualinterface()
                
                
            } catch {
                let nsError = error as NSError
                os_log(.debug, log: self.log, "did not start connection, error: %{public}@ / %zd", nsError.domain, nsError.code)
                self.status = "Error starting connection."
            }
            self.receivetunpacket()
        }
    }
    
    private func connectVirtualinterface() {
        let udpParams = NWParameters.udp
            // 送信先エンドポイント
            
        connection = NWConnection(host:"192.168.111.10" ,port:20000, using: udpParams)
        connection.stateUpdateHandler = { (newState) in
                switch(newState) {
                case .ready:
                    print("ready")
//                    self.send(message: "Hello,VirtualInterface3")
                    DispatchQueue.main.sync {
                        self.send(message: self.sendTextbox.text!)
                    }
                case .waiting(let error):
                    print("waiting")
                    print(error)
                case .failed(let error):
                    print("failed")
                    print(error)
                default:
                    print("defaults")
                    break
                }
            }
    
            // コネクション開始
            let connectionQueue = DispatchQueue(label: "sender")
            connection.start(queue: connectionQueue)
            print("connection start")
        
            
        }

        func send(message: String) {
            let data = message.data(using: .ascii)

            // 送信完了時の処理
            let completion = NWConnection.SendCompletion.contentProcessed { (error: NWError?) in
                print("送信完了")
            }
            // 送信
            connection.send(content: data, completion: completion)
            
        }
    
    
    private func receivetunpacket() {
        let tunnel : NEPacketTunnelProvider
        tunnel = NEPacketTunnelProvider()
        print("OK ------------------------------------------------")
        tunnel.packetFlow.readPackets { (packets: [Data], protocols: [NSNumber]) in
            print("OK ------------------------------------------------")
            self.Receive = "OK"
            for packet in packets {
                // This is where encrypt() should reside
                // A comprehensive encryption is not easy and not the point for this demo
                // I just omit it

                //”data型の変数.map {String(format: "%02x",$0)}.joined()”でStringに変換できる
                let packetStr = packet.map{String(format: "%02x",$0)}.joined()
//                NSLog("hoge TUN to UDP packet: %@",packetStr)
                NSLog("huga ------------------------------------------------")
                NSLog("huga TUN to Application packet: %@",packetStr)
                print("huga ------------------------------------------------")
                print("huga TUN to Application packet: %@",packetStr)



                let myPacketManager = PacketManager()
                myPacketManager.getPacket(packet: packetStr)
                myPacketManager.printPacket()


            }


        }
        
        
        
        
    }


}

