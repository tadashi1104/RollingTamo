//
//  GameScene.swift
//  RollingTamo
//
//  Created by 鈴木 義 on 2015/05/29.
//  Copyright (c) 2015年 Tadashi.S. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameKit
import iAd
import AVFoundation
import Social

class GameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate, NADInterstitialDelegate {
    
    //ゲーム共通クラス
    let commFunc = GameCommonFunction()
    
    //Fire構造体
    struct fireStruct {
        //Playerの画像
        static let FireImage = ["Fire1", "Fire2"]
    }
    
    //Tamo構造体
    struct tamoStruct {
        //Playerの画像
        static let tamoImage = ["Tamo1", "Tamo2", "Tamo3", "Tamo4"]
    }
    
    //CMMotionManagerを格納する変数
    var motionManager: CMMotionManager!
    
    var myAudioPlayer:AVAudioPlayer!
    var accelerometerHandler:CMAccelerometerHandler?
    var highScoreLabel:SKLabelNode?
    var stageChangeLabel:SKLabelNode?
    var pauseLabel:SKLabelNode?
    
    //障害物作成timer
    var timer:NSTimer?
    //背景のスプライト
    var background:SKSpriteNode?
    //背景のノード
    var backgroundNode = SKNode()
    //Tamoのスプライト
    var tamo = SKSpriteNode(imageNamed: "Tamo1")
    //Tamoの設定用変数
    var tamoYposition:CGFloat = 0      //Tamoのy座標
    var tamoXposition:CGFloat = 0      //Tamoのx座標
    //障害物のスプライト
    var syougai:SKSpriteNode?
    //障害物のノード
    var syougaiNode = SKNode()
    //距離
    var km = 0
    var kmLabel: SKLabelNode?
    //初めてフラグ
    var fstFlg = true
    
    let firstMove = -80
    let diffMove = 20
    var move = -80
    let interval = 0.05
    
    //死亡フラグ
    var dethFlg = false
    //ステージ
    var stage = 1
    
    let syougaiCount = 100
    let stageChangeKm = 1200
    let wateDelete:NSTimeInterval = 1
    let wordTiming = 300
    let lastStage = 4
    let localizeCount = 10
    
    let playSound = SKAction.playSoundFileNamed("Haretsu.caf", waitForCompletion: false)  //効果音
    
    //NSUserDefaultsを生成
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func update(currentTime: CFTimeInterval) {
        tamo.position = CGPoint(x: tamo.position.x + self.tamoXposition, y: tamo.position.y)
        //画面の外に出たら、
        if(tamo.position.x < 0){
            //tamo.position.x = 0
            gameover()
        }else if(tamo.position.x > self.size.width){
            //tamo.position.x = self.size.width
            gameover()
        }
    }
    
    override func didMoveToView(view: SKView) {
        //nendの広告をロード
        NADInterstitial.sharedInstance().loadAdWithApiKey("3283b6a4b1b6f8b62479adee70c9639a38a0441c", spotId: "384122")
        
        //重力の設定とcontactDelegateの設定
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        //衝突を検知できるようにする
        self.physicsWorld.contactDelegate = self
        
        //BGMの開始
        bgmStart()
        
        //画面の設定
        setScreen()
        
        //CMMotionManagerを生成
        motionManager = CMMotionManager()
        
        //加速度の値の取得の間隔を設定する
        motionManager.accelerometerUpdateInterval = 0.1 //0.1秒ごとに取得
        
        //ハンドラを設定する
        let accelerometerHandler:CMAccelerometerHandler = {
            (data:CMAccelerometerData!, error:NSError!) -> Void in
            
            //ログにx,y,zの加速度を表示する
            //println("x:\(data.acceleration.x) y:\(data.acceleration.y) z:\(data.acceleration.z)")
        
            
            //キャラクターのx座標を設定（data.acceleration.xの値が小さすぎて座標には使えないので20をかける）
            self.tamoXposition = CGFloat(data.acceleration.x * 20)
        }
        self.accelerometerHandler = accelerometerHandler
        //取得開始して、上記で設定したハンドラを呼び出す
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: accelerometerHandler)
        
        //タイマーの開始
        timerStart()
    }
    
    func bgmStart() {
        //AVAudioSessionの設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //カテゴリの設定(別アプリでオーディオ再生中にアプリを起動しても停止しない)
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
        } catch _ {
        }
        do {
            //AVFoundationで利用開始
            try audioSession.setActive(true)
        } catch _ {
        }
        
        //AudioPlayerの設定
        myAudioPlayer = commFunc.setAudioPlayer("BGM", audioFileType: "caf", loopCount: -1)
        
        //AVAudioPlayerのデリゲートをセット.
        //myAudioPlayer.delegate = self
        
        //myAudioPlayerの再生.
        myAudioPlayer.play()
    }
    
    func setScreen() {
        
        //ハイスコアの設定
        setHighScore()
        
        //背景の設定
        setBackground("Background1")
        
        //Tamoの配置
        //Playerのパラパラアニメーション作成に必要なSKTextureクラスの配列を定義
        var tamoTexture = [SKTexture]()
        
        //パラパラアニメーションに必要な画像を読み込む
        for imageName in tamoStruct.tamoImage {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .Linear
            tamoTexture.append(texture)
        }
        
        //パラパラ漫画のアニメーションを作成
        //第１引数playerTextureはパラパラさせたいSKTextureの配列、第２引数timePerFrameはぱらぱらさせる間隔
        let animation = SKAction.animateWithTextures(tamoTexture, timePerFrame: 0.2)
        let loopAnimation = SKAction.repeatActionForever(animation)
        self.tamo = SKSpriteNode(texture: tamoTexture[0])
        
        
        
        //スタート時の位置
        tamo.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.35)
        //Tamoのサイズ
        tamo.size = CGSize(width: 50, height: 50)
        //physicsBodyの設定
        tamo.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        tamo.physicsBody?.linearDamping = 0 //流体や空気抵抗をシミュレート
        tamo.physicsBody?.allowsRotation = false //ぶつかった時に回転するかどうか
        tamo.physicsBody?.collisionBitMask = 1
        tamo.physicsBody?.contactTestBitMask = 1
        tamo.runAction(loopAnimation)
        
        self.addChild(tamo)
        
        //障害物を設定
        setSyougai("Syougai1")
        
        //スコア作成
        kmLabel = commFunc.setSKLabel("k8x12L", color: UIColor.whiteColor(), fontSize: 28, zPosition: 1, point: CGPoint(x: 55, y: self.size.height - 30))
        self.addChild(kmLabel!)
    }
    
    func setHighScore() {
        //ハイスコアラベルの設定
        highScoreLabel = commFunc.setSKLabel("k8x12L", color: UIColor.whiteColor(), fontSize: 21, zPosition: 1, point: CGPoint(x: self.size.width - 75, y: self.size.height - 30))
        //Hi-Scoreを取得、設定
        highScore()
        self.addChild(highScoreLabel!)
    }
    
    func highScore() {
        //NSUserDefaultsで保存したハイスコアを読み込む
        var highscore:Int = defaults.integerForKey("HIGHSCORE")
        
        //今回の得点がハイスコアよりも大きければ、今回の得点を保存する
        if(km > highscore){
            //HIGHSCOREという名前でint型でpointを保存する
            defaults.setObject(km, forKey: "HIGHSCORE")
            //保存した値を反映する
            defaults.synchronize()
            //GameCenterにスコアを送信
            commFunc.reportScoreToGC("RollingTamo2", score: Int64(km))
            
            let nc = NSNotificationCenter.defaultCenter()
            nc.postNotificationName("testNotification", object: nil, userInfo: ["number": km])
        }
        //ハイスコアをラベルに表示する
        highScoreLabel?.text = NSString(format: "Hi-Score:%dkm",self.defaults.integerForKey("HIGHSCORE")) as String
    }
    
    func setBackground(imageName:Set<String>) {
        
        //背景を削除
        self.backgroundNode.removeAllChildren()
        self.backgroundNode.removeFromParent()
        
        //ステージ毎に背景色を決定
        switch stage {
        case 1:
            self.backgroundColor = UIColor.greenColor()
            return
        case 2:
            self.backgroundColor = UIColor.brownColor()
            return
        default:
            break
        }
        
        setBackGroundAction(imageName)
    }
    
    func setBackGroundAction(imageName:String) {
        
        //背景画像を読み込む
        let texture = SKTexture(imageNamed: imageName)
        //Nearest：画像を拡大・縮小する際に、処理が早いが画像は粗くなる
        //Linear：画像を拡大・縮小する際に、処理は遅いが画像はきれい
        texture.filteringMode = .Nearest
        //必要な画像枚数を算出
        //最低3枚を確保しておく
        //画面の横幅 / 背景画像の横幅 = 画面を埋めることが出来る背景画像の枚数
        let needNumber = 3.0 + (self.frame.size.height / texture.size().height)
        
        //アニメーションを作成
        //moveBy：移動にかかる時間(秒)と距離(シーン座標)を指定してノードを移動させる
        let dy = -self.size.height
        let move = CGFloat(abs(self.move))
        let moveAnime = SKAction.moveBy(CGVector(dx: 0, dy: dy), duration: NSTimeInterval(self.size.width / move))
        let resetAnime = SKAction.moveBy(CGVector(dx: 0, dy: self.size.height), duration: 0.0)
        //repeatActionForever：actionで渡したSKActionを永遠に繰り返す
        let repeatForeverAnime = SKAction.repeatActionForever(SKAction.sequence([moveAnime, resetAnime]))
        
        //画像の配置とアニメーションを設定
        for var i:CGFloat = 0; i < needNumber; ++i {    //算出した画像の枚数分ループ
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: self.frame.size.width, height: self.frame.size.height)
            sprite.zPosition = -100.0
            //画像を順番に配置
            sprite.position = CGPoint(x: sprite.size.width / 2.0, y: i * self.frame.size.height)
            sprite.runAction(repeatForeverAnime)
            self.backgroundNode.addChild(sprite)
        }
        
        self.addChild(self.backgroundNode)
    }
    
    func setSyougai(imageName:String) {
        //障害の追加
        setAddSyougai(imageName)
        //障害のアニメーション
        setSyougaiAnime()
    }
    
    func setAddSyougai(imageName:String) {
        //障害物の初期化
        self.syougaiNode.removeAllChildren()
        self.syougaiNode.removeFromParent()
        self.addChild(syougaiNode)
        self.syougaiNode.position = CGPoint(x: 0, y: 0)
        
        //障害物の座標を指定するための変数
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        //障害物を100個配置します
        for i in 0..<syougaiCount {
            let syougai = SKSpriteNode(imageNamed: imageName)
            var width = 50
            var height = 50
            switch stage {
            case 1:
                width = 50
                height = 50
            case 2:
                width = 70
                height = 70
            case 3:
                width = 65
                height = 65
            case 4:
                width = 80
                height = 80
            default:
                width = 50
                height = 50
            }
            syougai.size = CGSize(width: width, height: height)
            let syougaiTexture = SKTexture(imageNamed: imageName)
            syougaiTexture.filteringMode = .Linear
            
            syougai.physicsBody = SKPhysicsBody(circleOfRadius: 25)
//            syougai.physicsBody = SKPhysicsBody(texture: syougaiTexture, size: syougaiTexture.size())
            syougai.physicsBody?.collisionBitMask = 1
            syougai.physicsBody?.contactTestBitMask = 1
            syougai.physicsBody?.allowsRotation = false
            syougai.physicsBody?.dynamic = false
            
            //次の障害の位置をランダムで配置
            let randIntX = arc4random_uniform(UInt32(self.size.width))
            let randIntY = arc4random_uniform(100)
            x = CGFloat(randIntX)
            if(fstFlg == false && i == 0) {
                y += self.size.height  //最初はスタート地点から少し上から開始
                //y += CGFloat(randIntY) + 50
            } else if(i == 0) {
                y += self.size.height * 0.8
            } else {
                y += CGFloat(randIntY) + 50  //最低でも50以上、上に配置するようにするため+50
            }
            
            //syougaiNodeの上にブロックを配置する
            syougaiNode.addChild(syougai)
            syougai.position = CGPoint(x:x, y:y)
            
            if (i == syougaiCount-1) {
                self.syougai = syougai
            }
        }
    }

    func setSyougaiAnime() {
        //アニメーションの作成
        syougaiNode.removeAllActions()
        let moveAnime = SKAction.moveBy(CGVector(dx: 0, dy: move), duration: 0.5)
        let repeatForeverUnderAnime = SKAction.repeatActionForever(SKAction.sequence([moveAnime]))
        syougaiNode.runAction(repeatForeverUnderAnime)
    }
    
    func timerStart() {
        //タイマーを生成
        self.timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: "countUpKm", userInfo: nil, repeats: true)
    }
    
    func timerEnd() {
        //タイマーを破棄
        self.timer?.invalidate()
    }
    
    func countUpKm() {
        km += 3
        self.kmLabel?.text = "\(String(km))km"
        if((km % stageChangeKm) == 0) {
            fstFlg = false
            timerEnd()
            move -= diffMove
            stage += 1
            if (stage == lastStage + 1) {
                stage = 1
            }
            setBackground("Background" + String(stage))
            setSyougai("Syougai" + String(stage))
            setSyougaiAnime()
            setStageChangeLabel()
            timerStart()
        }
        //たまの独り言
        if ((Int(km) % wordTiming) == 0) {
            self.setWord(0)
        }
        //障害物が全てなくなったら再度作成
        if (self.syougai?.position.y < abs(self.syougaiNode.position.y)) {
            setSyougai("Syougai" + String(stage))
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //死んでいた場合
        if (dethFlg == true) {
            dethFlg = false
            //nend広告の表示
            var showResult: NADInterstitialShowResult
            showResult = NADInterstitial.sharedInstance().showAdWithSpotId("384122")
            //初期化F
            move = firstMove
            self.syougaiNode.speed = 1
            self.backgroundNode.speed = 1
            self.removeAllChildren()
            let scene = Title()
            scene.size = self.size
            self.view?.presentScene(scene)
        }else if (self.tamo.speed == 1) {
            //ポーズ処理
            pause()
        }else{  //
            self.pauseLabel?.removeAllActions()
            self.pauseLabel?.removeFromParent()
            self.syougaiNode.speed = 1
            self.backgroundNode.speed = 1
            self.tamo.speed = 1
            //加速度センサーのハンドラーを停止
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: self.accelerometerHandler)
            //BGMスタート
            bgmStart()
            //タイマー開始
            timerStart()
        }
    }
    
    func pause() {
        //それぞれ値を0にする
        tamoXposition = 0
        motionManager.stopAccelerometerUpdates()
        myAudioPlayer.pause()
        self.syougaiNode.speed = 0
        self.backgroundNode.speed = 0
        self.tamo.speed = 0
        timerEnd()
        let pauseLabel = SKLabelNode(fontNamed: "k8x12L")
        pauseLabel.text = "Pause"
        pauseLabel.fontSize = 62
        pauseLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        pauseLabel.fontColor = UIColor.whiteColor()
        pauseLabel.zPosition = 100
        let fadein = SKAction.fadeAlphaTo(0, duration: 0.5)
        let fadeout = SKAction.fadeAlphaTo(1, duration: 0.5)
        let sequence = SKAction.sequence([fadein, fadeout])
        let loop = SKAction.repeatActionForever(sequence)
        pauseLabel.runAction(loop)
        self.addChild(pauseLabel)
        self.pauseLabel = pauseLabel
    }
    
    func setStageChangeLabel() {
        //Stage Change Label作成
        let stageChangeLabel = SKLabelNode(fontNamed: "k8x12L")
        stageChangeLabel.text = "Stage Change!!"
        stageChangeLabel.fontSize = 42
        stageChangeLabel.position = CGPoint(x: self.size.width + 100, y: self.size.height * 0.5)
        stageChangeLabel.fontColor = UIColor.whiteColor()
        stageChangeLabel.zPosition = 90
        let move1 = SKAction.moveToX(self.size.width * 0.5, duration: 0.1)
        let move2 = SKAction.moveByX(20, y: 0, duration: 0.5)
        let move3 = SKAction.moveToX(-self.size.width - 100, duration: 0.1)
        let sequence = SKAction.sequence([move1, move2, move3])
        stageChangeLabel.runAction(sequence)
        self.addChild(stageChangeLabel)
        self.stageChangeLabel = stageChangeLabel
    }
    
    func setWord(flg:Int) {
        
        let randInt = arc4random_uniform(2)
        var word = "・・・。"
        
        if(flg == 1) {
            word = NSLocalizedString("wordGameOver", comment: "coment")
        }else if (randInt == 1) {
            let randWord = arc4random_uniform(UInt32(localizeCount))
            if randWord != 0 {
                word = NSLocalizedString("word\(randWord)", comment: "coment")
            }
        }else{
            return
        }
        
        let fukidashi = SKSpriteNode(imageNamed: "Fukidashi")
        fukidashi.size = CGSize(width: self.size.width * 0.9, height: self.size.height * 0.175)
        fukidashi.position = CGPoint(x: self.size.width * 0.5, y: 110)
        addChild(fukidashi)
        
        let wordLabel = commFunc.setSKLabel("k8x12L", color: UIColor.whiteColor(), fontSize: 21, zPosition: 2, point: CGPoint(x: self.size.width * 0.5, y: 110))
        wordLabel.text = word
        self.addChild(wordLabel)
        
        if word != NSLocalizedString("wordGameOver", comment: "coment") {
            let delete = SKAction.removeFromParent()
            let wate = SKAction.waitForDuration(2)
            let sequence = SKAction.sequence([wate, delete])
            fukidashi.runAction(sequence)
            wordLabel.runAction(sequence)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        runAction(playSound)
        gameover()
    }
    
    func gameover() {
        
        if dethFlg == true {
            return
        }
        
        myAudioPlayer.stop()
        motionManager.stopAccelerometerUpdates()
        tamoXposition = 0
        
        highScore()
        
        syougaiNode.speed = 0
        backgroundNode.speed = 0
        stage = 1
        tamo.removeFromParent()
        timerEnd()
        
        setWord(1)
        
        //Fireのパラパラアニメーション作成に必要なSKTextureクラスの配列を定
        var fireTexture = [SKTexture]()

        //パラパラアニメーションに必要な画像を読み込む
        for imageName in fireStruct.FireImage {
            let texture = SKTexture(imageNamed: imageName)
            texture.filteringMode = .Linear
            fireTexture.append(texture)
        }
        
        //パラパラ漫画のアニメーションを作成
        //第１引数playerTextureはパラパラさせたいSKTextureの配列、第２引数timePerFrameはぱらぱらさせる間隔
        let fireAnimation = SKAction.animateWithTextures(fireTexture, timePerFrame: 0.2)
        let loopFireAnimation = SKAction.repeatActionForever(fireAnimation)
    
        //キャラクターを生成し、アニメーションを設定
        let fire = SKSpriteNode(texture: fireTexture[0])
        fire.position = CGPoint(x: tamo.position.x, y: tamo.position.y)
        fire.runAction(loopFireAnimation)
        self.addChild(fire)
        dethFlg = true
    }
    
    //音楽再生が成功した時に呼ばれるメソッド.
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("Music Success")
    }
    
    //デコード中にエラーが起きた時に呼ばれるメソッド.
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        print("Music Error")
    }
    
    
    // MARK: NADInterstitialDelegate
    func didFinishLoadInterstitialAdWithStatus(status: NADInterstitialStatusCode) {
        switch(status.rawValue){
        case SUCCESS.rawValue:
            print("広告のロードに成功しました。")
            break
        case INVALID_RESPONSE_TYPE.rawValue:
            print("不正な広告タイプです。")
            break
        case FAILED_AD_REQUEST.rawValue:
            print("抽選リクエストに失敗しました。")
            break
        case FAILED_AD_DOWNLOAD.rawValue:
            print("広告のロードに失敗しました。")
            break default:
            break
        }
    }
    // ロード結果と対象の広告のSpotIDの通知を受け取る場合
    func didFinishLoadInterstitialAdWithStatus(status: NADInterstitialStatusCode, spotId: String!) {
        switch(status.rawValue){
        case SUCCESS.rawValue:
            print("広告のロードに成功しました。\(spotId)")
            break
        case INVALID_RESPONSE_TYPE.rawValue:
            print("不正な広告タイプです。")
            break
        case FAILED_AD_REQUEST.rawValue:
            print("抽選リクエストに失敗しました。")
            break
        case FAILED_AD_DOWNLOAD.rawValue:
            print("広告のロードに失敗しました。")
            break default:
            break
        }
    }
    
    func didClickWithType(type: NADInterstitialClickType) { switch(type.rawValue){
        case DOWNLOAD.rawValue:
            print("ダウンロードボタンがクリックされました。")
            break
        case CLOSE.rawValue:
            print("閉じるボタンあるいは広告範囲外の領域がクリックされました。")
            break default:
            break
        }
    }
    
}

class Title: SKScene, AVAudioPlayerDelegate, ADBannerViewDelegate {
    
    var startButton = UIButton()
    var banner = ADBannerView()
    var bannerIsVisible = false
    var myAudioPlayer : AVAudioPlayer!
    
    override func didMoveToView(view: SKView) {
        //重力の設定
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        //背景色の設定
        self.backgroundColor = UIColor.greenColor()
        //タイトルの配置
        let title = SKSpriteNode(imageNamed: "Title")
        title.size = CGSize(width: self.size.width, height: self.size.width)
        title.position = CGPoint(x: self.size.width * 0.5, y: self.size.height + 100)
        self.addChild(title)
        let moveAnime = SKAction.moveToY(self.size.height * 0.6, duration: 5)
        title.runAction(moveAnime)
        
        let startButton = UIButton()
        //表示されるテキスト
        startButton.setTitle("Start", forState: .Normal)
        //テキストの色
        startButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        //サイズ
        startButton.frame = CGRectMake(0, 0, 100, 30)
        //ポジション
        startButton.layer.position = CGPoint(x:self.size.width * 0.5, y:self.size.height * 0.75)
        //タップ時の処理
        startButton.addTarget(self, action: "touchButton", forControlEvents:.TouchUpInside)
        //フォント
        startButton.titleLabel?.font = UIFont(name: "k8x12L", size: CGFloat(50))
        //タグ
        startButton.tag = 1
        //配置
        self.view?.addSubview(startButton)
        self.startButton = startButton
        
        let banner = ADBannerView()
        banner.sizeToFit()
        banner.layer.position = CGPoint(x:self.size.width * 0.5,y:self.size.height - banner.frame.height * 0.5)
        banner.tag = 2
        banner.alpha = 0.0
        banner.delegate = self
        self.view?.addSubview(banner)
        self.banner = banner
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
        } catch _ {
        }
        do {
            try audioSession.setActive(true)
        } catch _ {
        }
        //再生する音源のURLを生成.
        let titleSoundFilePath : NSString = NSBundle.mainBundle().pathForResource("TitleMusic", ofType: "caf")!
        let titleFileURL : NSURL = NSURL(fileURLWithPath: titleSoundFilePath as String)
        //AVAudioPlayerのインスタンス化.
        myAudioPlayer =  try? AVAudioPlayer(contentsOfURL: titleFileURL)
        //AVAudioPlayerのデリゲートをセット.
        myAudioPlayer.delegate = self
        //myAudioPlayerの音量設定
        myAudioPlayer.volume = 0.2
        //myAudioPlayerの再生.
        myAudioPlayer.play()
    }
    
    
    //音楽再生が成功した時に呼ばれるメソッド.
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("Music Success")
    }
    
    //デコード中にエラーが起きた時に呼ばれるメソッド.
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        print("Music Error")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        if bannerIsVisible == false {
            self.banner.alpha = 1.0
            bannerIsVisible = true
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if bannerIsVisible == true {
            self.banner.alpha = 0.0
            bannerIsVisible = false
        }
    }
    
    func touchButton() {
        myAudioPlayer.stop()
        self.removeAllChildren()
        startButton.removeFromSuperview()
        
        let transition = SKTransition.doorwayWithDuration(1.0)
        
        let scene = GameScene()
        scene.scaleMode = .AspectFill
        scene.size = self.size
        self.view?.presentScene(scene, transition: transition)
    }
    
}
