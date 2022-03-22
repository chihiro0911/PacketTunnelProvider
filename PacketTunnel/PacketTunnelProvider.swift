import NetworkExtension
import os.log
import CryptoSwift


class PacketTunnelProvider: NEPacketTunnelProvider {
    private var session: NWUDPSession!
    private var observer: AnyObject?
    /// The tunnel connection.
    open var connection: NWTCPConnection?
    
    
    
    override init() {
        os_log(.debug, log: self.log, "init")
        super.init()
    }

    let log = OSLog(subsystem: "org.pluslab.SimpleTunnel", category: "provider")
    let queue = DispatchQueue(label: "TransparentProxyProvider", autoreleaseFrequency: .workItem)

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        NSLog("provider will start")
        self.queue.async {
            let settings = self.makeSettings()
 

            // Set up the tunnel.
//            self.setTunnelNetworkSettings(settings) { (error: Error?) -> Void in
//                if let error = error {
//                    print(error)
//                }
            // Set up the tunnel.
            self.setTunnelNetworkSettings(settings) { errorQ in
                NSLog("setTunnelNetworkSettings")
                if let error = errorQ as NSError? {
                    completionHandler(error)
                    NSLog("provider did not start, tunnel setup failed, error: %{public}@ / %zd", error.domain, error.code)
                    return
                }
                
                //connect UDP tunnel
                let endpoint = NWHostEndpoint(hostname:"10.0.3.90", port: "10003")
                let mypoint = NWHostEndpoint(hostname:"10.0.2.128", port: "20000")
                self.session = self.createUDPSession(to: endpoint, from: mypoint)
//                self.session = self.createUDPSessionThroughTunnel(to: endpoint, from: mypoint)
                NSLog("createUDPSession start")
                NSLog("session:%d",self.session)
                print(self.session.state)
                self.observer = self.session.observe(\.state, options: [.new]) { session, _ in
                    if session.state == .ready {
                        // The session is ready to exchange UDP datagrams with the server
                    }
                }

                
                
                //TUN -> CYP App
                self.packetFlow.readPackets { (packets: [Data], protocols: [NSNumber]) in
                    for packet in packets {
                        // This is where encrypt() should reside
                        // A comprehensive encryption is not easy and not the point for this demo
                        // I just omit it
                
                        //”data型の変数.map {String(format: "%02x",$0)}.joined()”でStringに変換できる
                        let packetStr = packet.map{String(format: "%02x",$0)}.joined()
        //                NSLog("hoge TUN to UDP packet: %@",packetStr)
                        NSLog("huga ------------------------------------------------")
                        NSLog("huga TUN to UDP packet: %@",packetStr)
                        
                        let myPacketManager = PacketManager()
                        myPacketManager.getPacket(packet: packetStr)
                        myPacketManager.printPacket()
                        
                        let encodebyteData = encode(packetStr)
                        
                        let encodeData = encodebyteData.map{String(format: "%02x",$0)}.joined()
                        NSLog("huga ------------------------------------------------")
                        NSLog("huga encode packet: %@",encodeData)


                        myPacketManager.getPacket(packet: encodeData)
                        myPacketManager.printPacket()
//
//
//                        // base64 から Data型へ
//                        let encodebyteData = encodeData.data(using: String.Encoding.utf8)
//
                        
                        //packetのLengthでカプセル化
                        let messageData: NSMutableData?
                        do {
                            /*
                             * Message format:
                             *
                             *  0 1 2 3 4 ... Length
                             * +-------+------------+
                             * |Length | Payload    |
                             * +-------+------------+
                             *
                             */
//                            let payload = try PropertyListSerialization.data(fromPropertyList: messageProperties, format: .binary, options: 0)
                            var totalLength: UInt32 = UInt32(encodebyteData.count + MemoryLayout<UInt32>.size)
//                            NSLog("totalLength: %@",totalLength)
                            messageData = NSMutableData(capacity: Int(totalLength))
                            messageData?.append(&totalLength, length: MemoryLayout<UInt32>.size)
                            messageData?.append(encodebyteData)
                        }
                        catch {
                            NSLog("Failed to create a data object from a message ")
                        }
                        
                        
                        //CYP App --my eth--> dst eth
                        self.session?.writeDatagram(messageData as! Data, completionHandler: { (error: Error?) in
                            NSLog("writeDatagram")
                            if let error = error {
                                print(error)

                            }
                        })
                        
                    }
                
                }
            
                
//                let message = packetStr.data(using: String.Encoding.utf8)
//                let message = "Hello Provider".data(using: String.Encoding.utf8)
//                self.packetFlow.writePackets(message:[Data], withProtocols: <#[NSNumber]#>)
                
                self.udpToTun()
                NSLog("udpToTun")
                
                //受信確認用
                self.packetFlow.readPackets { (packets: [Data], protocols: [NSNumber]) in
                    for packet in packets {
                        // This is where encrypt() should reside
                        // A comprehensive encryption is not easy and not the point for this demo
                        // I just omit it
                
                        //”data型の変数.map {String(format: "%02x",$0)}.joined()”でStringに変換できる
                        let packetStr = packet.map{String(format: "%02x",$0)}.joined()
        //                NSLog("hoge TUN to UDP packet: %@",packetStr)
                        NSLog("huga ------------------------------------------------")
                        NSLog("huga TUN to UDP packet: %@",packetStr)
                        
                        let myPacketManager = PacketManager()
                        myPacketManager.getPacket(packet: packetStr)
                        myPacketManager.printPacket()
                        
                        
                    }
                
                }
                
                
               
                self.setupOutboundRead()
                completionHandler(nil)
                NSLog("provider did start")
            }
            
            

            
    // Kick off the connection to the server.
//                self.connection = self.createUDPConnection(to: endpoint, enableTLS:false, tlsParameters:nil, delegate:nil)

            // Register for notificationes when the connection status changes.
            
//                connection!.addObserver(self, forKeyPath: "state", options: .initial, context: &ClientTunnel.observerContext)
            //connection!.addObserver(self, forKeyPath: "state", options: .initial, context: &connection)
            
            
//                //コネクションにパケットを書き込む
//                self.connection.sendMessage("Hello Packettunnel") { error in
//                    if let sendError = error {
//                        self.delegate.tunnelConnectionDidClose(self, error: sendError)
//                        return
//                    }
//
//                    // Read more packets.次のパケットを読み込む
//                    self.packetFlow.readPackets { inPackets, inProtocols in
//                        self.handlePackets(inPackets, protocols: inProtocols)
//                    }
//                }
            
            // All is cool.  Start the code that reads and discards packets
            // and then complete the start request.
            
        }
    }
    
    private func makeSettings() -> NEPacketTunnelNetworkSettings {
        dispatchPrecondition(condition: .onQueue(self.queue))
        
        // Set up the IPv4 configuration for our tunnel.
        //
        // The `addresses` and `subnetMasks` properties define the IPv4 networks
        // ‘directly connected’ to this VPN interface.  Most VPN networks are
        // point-to-point, and thus this isn’t a network per set but rather an
        // IP address (hence the 255.255.255.255 subnet mask).
        
        //「アドレス」および「サブネットマスク」プロパティは、この VPN インターフェースに「直接接続されている」IPv4 ネットワークを定義します。 ほとんどの VPN ネットワークはポイントツーポイントであるため、これはセットごとのネットワークではなく、むしろ IP アドレスです (したがって、255.255.255.255 サブネット マスク)。
        
        let v4Settings = NEIPv4Settings(addresses: ["192.168.111.10"], subnetMasks: ["255.255.255.255"])

        // `NEIPv4Settings` properties:
        //
        // In a real product you need to think carefully about whether you want
        // to create a split or full tunnel.  This creates a split tunnel,
        // claiming traffic to the 192.168.42/24 network.  To create a full
        // tunnel, use the default route (`NEIPv4Route.default()`).
        //実際の製品では、必要かどうかを慎重に検討する必要があります。
//        スプリットまたはフル トンネルを作成します。 これにより、スプリット トンネルが作成されます。
//        192.168.42/24 ネットワークへのトラフィックを主張しています。 完全なトンネルを作成するには、デフォルト ルート (`NEIPv4Route.default()`) を使用します。
        
        v4Settings.includedRoutes = [ NEIPv4Route(destinationAddress: "192.168.111.11", subnetMask: "255.255.255.0") ]
        // `excludedRoutes` is irrelevant to this testbed.
        
        // Create the overall tunnel configuration.
        
        // The address you pass to `tunnelRemoteAddress` is intended to be the
        // IP address of the actual VPN server that you connected to.  A real
        // VPN would connect to `self.protocolConfiguration.serverAddress` and
        // then report the remote address here.  In our case we are not actually
        // using a VPN server, so there’s nothing to connect to, so we just hard
        // code a value of 93.184.216.34, which is the current IP address of
        // `example.com`.
        
        //「tunnelRemoteAddress」に渡すアドレスは、
//        接続した実際の VPN サーバーの IP アドレス。 リアル
//        VPN は「self.protocolConfiguration.serverAddress」に接続し、
//        次に、ここでリモート アドレスを報告します。 私たちの場合、実際にはそうではありません
//        VPN サーバーを使用しているため、接続するものがないため、
//        「example.com」の現在の IP アドレスである 93.184.216.34 の値をコーディングします。

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.3.90")

        // `NETunnelNetworkSettings` properties:
        //
        // `dnsSettings` and `proxySettings` are irrelevant to us.
        
        // `NEPacketTunnelNetworkSettings` properties…
        //
        settings.ipv4Settings = v4Settings
        // settings.ipv6Settings = ?
//        settings.tunnelOverheadBytes = 4
        settings.mtu = 1400
        // Set either `tunnelOverheadBytes` or `mtu`.

        return settings
    }
    
    private func setupOutboundRead() {
        self.packetFlow.readPacketObjects { packets in

            let protocolsByFamily = Dictionary(zip(
                packets.map { $0.protocolFamily },
                repeatElement(1, count: Int.max)
            ), uniquingKeysWith: +)
            let v4Count = protocolsByFamily[sa_family_t(AF_INET)] ?? 0
            let v6Count = protocolsByFamily[sa_family_t(AF_INET6)] ?? 0
            let otherCount = packets.count - v4Count - v6Count
            NSLog("provider did read packets, v4: %d, v6: %d, ?: %d", v4Count, v6Count, otherCount)
            NSLog("provider did read packets,  %d", packets)

            self.setupOutboundRead()
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("provider will stop, reason: %zd", reason.rawValue)
        self.queue.async {
            completionHandler()
            NSLog("provider did stop")
        }
    }


    

    /// Send a message to the tunnel server.
    //public func sendMessage(_ messageProperties: [String: Any], completionHandler: @escaping (Error?) -> Void) {
    //    NSLog("SimpleTunnelServices_sendMessage")
    //    guard let messageData = serializeMessage(messageProperties) else {
    //        NSLog("sendMessage error")
    //        return
    //    }
    //    connection?.write(messageData, completionHandler: completionHandler )
    //}



    func udpToTun() {
        // It's callback here
        //eth -> tun -> CYP App(たぶん)
        session?.setReadHandler({ (_packets: [Data]?, error: Error?) -> Void in
            if let packets = _packets {
                // This is where decrypt() should reside, I just omit it like above
                
                //デカプセル化ポイント↓
                for packet in packets {
                    let packetStr = packet.map{String(format: "%02x",$0 as CVarArg)}.joined()
                    NSLog("huga ------------------------------------------------")
                    NSLog("huga UDP to TUN packet: %@",packetStr)
                    
                    
                    let myPacketManager = PacketManager()
                    myPacketManager.getPacket(packet: packetStr)
                    myPacketManager.printPacket()
                    
                    let decodeData = decode(packet)
                    NSLog("huga ------------------------------------------------")
                    NSLog("huga decode packet: %@",decodeData)
                    
                    
                    myPacketManager.getPacket(packet: decodeData)
                    myPacketManager.printPacket()
                }
                //デカプセル化ポイント↑
                
                //CYP App -> TUN
                self.packetFlow.writePackets(packets, withProtocols: [NSNumber](repeating: AF_INET as NSNumber, count: packets.count))
    //                self.packetFlow.writePackets(packets, withProtocols: [NSNumber](repeating: AF_INET6 as NSNumber, count: packets.count))//お試しでAF_INET6にしてみる
            }
        }, maxDatagrams: NSIntegerMax)
    }
}



/// 暗号化のキー（16文字）
    let encryptionKey = "samplesamplesamp"

    /// データをシフト演算するキー（16文字の数字）
//    let encryptionIv = "1111122222333339"
    let encryptionIv = getInitializationVector()
    

//    let encryptionIv = AES.randomIV(AES.blockSize)
//let encryptionIv = AES.randomIV(16)
    
    /// 暗号化
    /// - Parameter target: 暗号化したい文字列
    func encode(_ target: String) -> Data {
        NSLog("encryptionIv: %@",encryptionIv)

        do {
            // 暗号化処理
            // AES インスタンス化
            let aes = try AES(key: encryptionKey, iv: encryptionIv)
            let encrypt = try aes.encrypt(Array(target.utf8))
            
            
            

            // Data 型変換
            let data = Data(encrypt)
//            // base64 変換
//            let base64Data: Data = data.base64EncodedData() as Data

//            // base64文字列をUTF-8に変換して返す
//            return String(data: base64Data, encoding: String.Encoding.utf8) ?? ""
            
            return data

        } catch {
            // エラー処理
            var int = "error"
            return Data(bytes: &int, count: MemoryLayout<Int>.size)
        }
    }


/// 複合化
    /// - Parameter base64: 暗号化されている文字列
    func decode(_ data: Data) -> String {

        do {
            // AES インスタンス化
            let aes = try AES(key: encryptionKey, iv: encryptionIv)

            // base64 から Data型へ
//            guard let byteData = base64.data(using: String.Encoding.utf8) else { return "" }
            // base64 デーコード
//            guard let data = Data(base64Encoded: base64) else { return "" }

            // UInt8 配列の作成
            let aBuffer = Array<UInt8>(data)
            // AES 複合
            let decrypted = try aes.decrypt(aBuffer)

            // UTF-8に変換して返す
            return String(data: Data(decrypted), encoding: .utf8) ?? ""
        } catch {
            // エラー処理
            return ""
        }
    }

// ----- Initialization Vector -----
     func getInitializationVector() -> String {
        let s = randomString(length: 16)
        return s
    }

    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let l = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(l)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
