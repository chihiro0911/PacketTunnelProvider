//
//  Packet.swift
//  Tunnel
//
//  Created by k15061kk on 2018/12/08.
//  Copyright © 2018年 AIT. All rights reserved.
//

import Foundation
import CoreFoundation

open class PacketManager{
    //ipv6 packet
    var Version : String!
    var TrafficClass : String!
    var FlowLabel : String!
    var PayloadLength : String!
    var NextHeader : String!
    var HopLimit : String!
    var SourceAddress : String!
    var DestinationAddress : String!
    var Data : String!

    //udp
    var udpSPort : String!
    var udpDPort : String!
    var udpLength : String!
    var udpChecksum : String!
    var udpBody : String!
    
    //ipv6 pointer  (x,y)x文字目からy文字目が範囲
    let VersionPointer : [Int] = [0,1]
    let TrafficClassPointer : [Int] = [1,3]
    let FlowLabelPointer: [Int] = [3,8]
    let PayloadLengthPointer: [Int] = [8,12]
    let NextHeaderPointer: [Int] = [12,14]
    let HopLimitPointer: [Int] = [14,16]
    let SourceAddressPointer: [Int] = [16,48]//16 32
    let DestinationAddressPointer: [Int] = [48,80]//24 31
    let DataPointer: [Int] = [80,-1]//31 -1
    
    //udp pointer
    let udpSPortPointer: [Int] = [0,4]
    let udpDPortPointer: [Int] = [4,8]
    let udpLengthPointer: [Int] = [8,12]
    let udpChecksumPointer: [Int] = [12,16]
    let udpBodyPointer: [Int] = [16,-1]
    
    open func getPacket(packet: String) {
        Version = String(packet[packet.index(packet.startIndex, offsetBy: VersionPointer[0])..<packet.index(packet.startIndex, offsetBy: VersionPointer[1])])
        TrafficClass = String(packet[packet.index(packet.startIndex, offsetBy: TrafficClassPointer[0])..<packet.index(packet.startIndex, offsetBy: TrafficClassPointer[1])])
        FlowLabel = String(packet[packet.index(packet.startIndex, offsetBy: FlowLabelPointer[0])..<packet.index(packet.startIndex, offsetBy: FlowLabelPointer[1])])
        PayloadLength = String(packet[packet.index(packet.startIndex, offsetBy: PayloadLengthPointer[0])..<packet.index(packet.startIndex, offsetBy: PayloadLengthPointer[1])])
        NextHeader = String(packet[packet.index(packet.startIndex, offsetBy: NextHeaderPointer[0])..<packet.index(packet.startIndex, offsetBy: NextHeaderPointer[1])])
        HopLimit = String(packet[packet.index(packet.startIndex, offsetBy: HopLimitPointer[0])..<packet.index(packet.startIndex, offsetBy: HopLimitPointer[1])])
        SourceAddress = String(packet[packet.index(packet.startIndex, offsetBy: SourceAddressPointer[0])..<packet.index(packet.startIndex, offsetBy: SourceAddressPointer[1])])
        DestinationAddress = String(packet[packet.index(packet.startIndex, offsetBy: DestinationAddressPointer[0])..<packet.index(packet.startIndex, offsetBy: DestinationAddressPointer[1])])
        Data = String(packet[packet.index(packet.startIndex, offsetBy: DataPointer[0])..<packet.index(packet.endIndex, offsetBy: DataPointer[1])])
    }
    
    open func printPacket(){
        NSLog("huga version = %@",self.Version)
        NSLog("huga traffi class = %@",self.TrafficClass)
        NSLog("huga flaw label = %@",self.FlowLabel)
        NSLog("huga payload length = %@",self.PayloadLength)
        NSLog("huga next header = %@",self.NextHeader)
        NSLog("huga hop limit = %@",self.HopLimit)
        NSLog("huga src address = %@",self.SourceAddress)
        NSLog("huga dst address = %@",self.DestinationAddress)
        NSLog("huga data = %@",self.Data)
        if(self.NextHeader == "11"){
            NSLog("huga --------udp body-------- ")
            getUdpBody(Data: self.Data)
            NSLog("huga Source Port = %@(16)   %d(10)",self.udpSPort,Int(self.udpSPort, radix: 16)!)
            NSLog("huga Dist Port = %@(16)   %d(10)",self.udpDPort,Int(self.udpDPort, radix: 16)!)
            NSLog("huga Length = %@",self.udpLength)
            NSLog("huga Checksum = %@",self.udpChecksum)
            NSLog("huga udp Body = %@",self.udpBody)
        }
        NSLog("huga ------------------------------------------------")
    }
    
    open func getUdpBody(Data: String){
        udpSPort = String(Data[Data.index(Data.startIndex, offsetBy: udpSPortPointer[0])..<Data.index(Data.startIndex, offsetBy: udpSPortPointer[1])])
        udpDPort = String(Data[Data.index(Data.startIndex, offsetBy: udpDPortPointer[0])..<Data.index(Data.startIndex, offsetBy: udpDPortPointer[1])])
        udpLength = String(Data[Data.index(Data.startIndex, offsetBy: udpLengthPointer[0])..<Data.index(Data.startIndex, offsetBy: udpLengthPointer[1])])
        udpChecksum = String(Data[Data.index(Data.startIndex, offsetBy: udpChecksumPointer[0])..<Data.index(Data.startIndex, offsetBy: udpChecksumPointer[1])])
        udpBody = String(Data[Data.index(Data.startIndex, offsetBy: udpBodyPointer[0])..<Data.index(Data.endIndex, offsetBy: udpBodyPointer[1])])
    }
}

