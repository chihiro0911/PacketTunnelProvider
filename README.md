# PacketTunnelTestbed
## 概要
Xcode11.2で動作を確認しています．\
異なるバージョンでは動作しない可能性があります．\
[ここから](https://developer.apple.com/download/more)Xcode11.2をダウンロードできます．\
アプリケーションでは[NetworkExtension](https://developer.apple.com/documentation/networkextension)を利用します．\
NetworkExtensionはシミュレータでは動作しないため実機で動作の確認を行ってください．\
NetworkExtensionを利用するには[Apple Developer](https://developer.apple.com/jp/)に登録する必要があります．

## 使い方
アプリケーションを使用する前にApp IDsを書き換える必要があります．\
書き換える箇所は以下の通りです．
- PacketTunnelTestbed，PacketTunnel両方のターゲットのbundle ID
- OSlogオブジェクトを定義するsubsystemプロパティ(PacketTunnelTestbed，PacketTunnelに各一箇所)
- NETunnelProviderProtocolのproviderBundleIdentifierプロパティ(PacketTunnelTestbedに二箇所)

ビルドする際はApp-iOSをターゲットにしてください．\
アプリケーション起動後の手順は以下の通りです．
1. アプリケーション起動後Configureをタップします．
1. VPNを許可に関するアラートが表示されますが許可を選択してください．
1. Connectをタップすると接続します．
1. ステータスバーにVPNと表示されていれば構築が完了しています．


## 補足
1. entitlementsファイルの内容は変更が反映されない場合があるためバイナリで確認する必要があります．ファイルの内容を確認するコマンドと正しいファイルの内容を記載します．\
`codesign -d entitlements :- App-iOS.app`
```
<plist version="1.0">
<dict>
    …
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
    </array>
    …
</dict>
</plist>
```

  `codesign -d --entitlements :- App-iOS.app/PlugIns/PacketTunnel.appex`
```
<plist version="1.0">
<dict>
    …
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>packet-tunnel-provider</string>
    </array>
    …
</dict>
</plist>
```
アプリケーションへのパスはXcode内のProductsファイルから対象のアプリケーションをドラッグすることで入力を省略できます．

1. plistファイルを確認するコマンドと正しいファイルの内容を記載します．\
`plutil -convert xml1 -o PacketTunnelTestbed.app/PlugIns/Provider.appex/Info.plist`
```
<plist>
<dict>
    …
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    …
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.networkextension.packet-tunnel</string>
        <key>NSExtensionPrincipalClass</key>
        <string>Provider.PacketTunnelProvider</string>
    </dict>
    …
</dict>
</plist>
```

1.
# PacketTunnelProvider
