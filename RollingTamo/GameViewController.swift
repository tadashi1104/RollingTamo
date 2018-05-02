//
//  GameViewController.swift
//  RollingTamo
//
//  Created by 鈴木 義 on 2015/05/29.
//  Copyright (c) 2015年 Tadashi.S. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import Social

class GameViewController: UIViewController, UIApplicationDelegate, NADInterstitialDelegate {
    var myTwitterButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 登録
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "handleTestNotification:", name: "testNotification", object: nil)
        
        //シーンの作成
        //let scene = GameScene()
        let scene = Title()
        //View ControllerのViewをSKView型として取り出す
        let view = self.view as! SKView
        //シーンのサイズをビューに合わせる
        scene.size = view.frame.size
        scene.scaleMode = .AspectFill
        //ビュー上にシーンを表示
        view.presentScene(scene)
        
    }
    
    deinit {
        print("deinit call")
        //イベントリスナーの削除
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleTestNotification(notification: NSNotification) {
        
        var score = 0
        
        // 変数宣言時にアンラップ & キャストする方法
        if let userInfo = notification.userInfo {
            let value = userInfo["number"]! as! Int
            let plus10 = value + 10
            println(plus10)
            score = value
        }
        
        // SLComposeViewControllerのインスタンス化.
        // ServiceTypeをTwitterに指定.
        myComposeView = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        
        // 投稿するテキストを指定.
        var str = NSLocalizedString("Tweet", comment: "comment")
        
        myComposeView.setInitialText(str.stringByReplacingOccurrencesOfString("[Score]", withString: "\(score)", options: [], range: nil))
        
        // 投稿する画像を指定.
        myComposeView.addImage(UIImage(named: "TamoIcon.png"))
        
        // myComposeViewの画面遷移.
        self.presentViewController(myComposeView, animated: true, completion: nil)
    }
    
    var myComposeView : SLComposeViewController!
    
    // ボタンイベント.
    func postToTwitter(info: NSNotification!) {
        
        var val:Int?
        
        if let userInfo = info.userInfo {
            let value = userInfo["Score"]! as! Int
            val = value
        }
        
        
        
        // SLComposeViewControllerのインスタンス化.
        // ServiceTypeをTwitterに指定.
        myComposeView = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        
        // 投稿するテキストを指定.
        myComposeView.setInitialText("Twitter Test from Swift \(val?)")
        
        //        // 投稿する画像を指定.
        //        myComposeView.addImage(UIImage(named: "oouchi.jpg"))
        
        // myComposeViewの画面遷移.
        self.presentViewController(myComposeView, animated: true, completion: nil)
    }
    
    
    func showButtonClicked() {
        NADInterstitial.sharedInstance().loadAdWithApiKey("308c2499c75c4a192f03c02b2fcebd16dcb45cc9", spotId: "213208")

        
        // SpotIDを指定する場合
        var showResult: NADInterstitialShowResult
        showResult = NADInterstitial.sharedInstance().showAdWithSpotId("213208")

        showResult = NADInterstitial.sharedInstance().showAd()
        switch(showResult.rawValue){
        case AD_SHOW_SUCCESS.rawValue:
            print("広告の表示に成功しました。")
            break
        case AD_SHOW_ALREADY.rawValue:
            print("既に広告が表示されています。")
            break
        case AD_FREQUENCY_NOT_REACHABLE.rawValue:
            print("広告のフリークエンシーカウントに達していません。")
            break
        case AD_LOAD_INCOMPLETE.rawValue:
            print("抽選リクエストが実行されていない、もしくは実行中です。")
            break
        case AD_REQUEST_INCOMPLETE.rawValue:
            print("抽選リクエストに失敗しています。")
            break
        case AD_DOWNLOAD_INCOMPLETE.rawValue:
            print("広告のダウンロードが完了していません。")
            break default:
            break
        }
    }
    
    func showWithSpotIdButtonClicked(notification: NSNotification) {
        
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    override func didReceiveMemoryWarning() {
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
