//
//  StickHeroGameScene.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/19.
//  Copyright © 2015年 koofrank. All rights reserved.
//

import SpriteKit

class StickHeroGameScene: SKScene, SKPhysicsContactDelegate {
    var gameOver = false {
        willSet {
            if (newValue) {
                //记录分数
                isBegin = false
                isEnd = false
                score = 0
                nextLeftStartX = 0
                removeAllChildren()
                start()
            }
            
        }
    }
    
    let StackHeight:CGFloat = 400.0
    let StackMaxWidth:CGFloat = 300.0
    let StackMinWidth:CGFloat = 100.0
    let gravity:CGFloat = -100.0
    let StackGapMinWidth:Int = 80
    let HeroSpeed:CGFloat = 760
 
    var isBegin = false
    var isEnd = false
    var leftStack:SKShapeNode?
    var rightStack:SKShapeNode?
    
    var nextLeftStartX:CGFloat = 0
    var stickHeight:CGFloat = 0
    
    var score = 0 {
        willSet {
            let scoreBand = childNodeWithName(StickHeroGameSceneChildName.ScoreName.rawValue) as? SKLabelNode
            scoreBand?.text = "\(newValue)"
            scoreBand?.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: 0.1), SKAction.scaleTo(1, duration: 0.1)]))
            
            if (newValue == 1) {
                let tip = childNodeWithName(StickHeroGameSceneChildName.TipName.rawValue) as? SKLabelNode
                tip?.runAction(SKAction.fadeAlphaTo(0, duration: 0.4))
            }
        }
    }
    
    lazy var playAbleRect:CGRect = {
        let maxAspectRatio:CGFloat = 16.0/9.0 // iPhone 5"
        let maxAspectRatioWidth = self.size.height / maxAspectRatio
        let playableMargin = (self.size.width - maxAspectRatioWidth) / 2.0
        return CGRectMake(playableMargin, 0, maxAspectRatioWidth, self.size.height)
        }()
    
    lazy var walkAction:SKAction = {
        var textures:[SKTexture] = []
        for i in 0...1 {
            let texture = SKTexture(imageNamed: "human\(i + 1).png")
            textures.append(texture)
        }
        
        let action = SKAction.animateWithTextures(textures, timePerFrame: 0.15, resize: true, restore: true)
        
        return SKAction.repeatActionForever(action)
        }()
    
    //MARK: - override
    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPointMake(0.5, 0.5)
        physicsWorld.contactDelegate = self
    }

    override func didMoveToView(view: SKView) {
        start()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !isBegin && !isEnd {
            isBegin = true
            
            let stick = loadStick()
            let hero = childNodeWithName(StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
     
            let action = SKAction.resizeToHeight(CGFloat(DefinedScreenHeight - StackHeight), duration: 1.5)
            stick.runAction(action, withKey:StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            
            let scaleAction = SKAction.sequence([SKAction.scaleYTo(0.9, duration: 0.05), SKAction.scaleYTo(1, duration: 0.05)])
            let loopAction = SKAction.group([SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowAudioName.rawValue, waitForCompletion: true)])
            stick.runAction(SKAction.repeatActionForever(loopAction), withKey: StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            hero.runAction(SKAction.repeatActionForever(scaleAction), withKey: StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
            
            return
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if isBegin && !isEnd {
            isEnd  = true
            
            let hero = childNodeWithName(StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            hero.removeActionForKey(StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
            hero.runAction(SKAction.scaleYTo(1, duration: 0.04))
            
            let stick = childNodeWithName(StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
            stick.removeActionForKey(StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            stick.removeActionForKey(StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            stick.runAction(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowOverAudioName.rawValue, waitForCompletion: false))
            
            stickHeight = stick.size.height;
            
            let action = SKAction.rotateToAngle(CGFloat(-M_PI / 2), duration: 0.4, shortestUnitArc: true)
            let playFall = SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickFallAudioName.rawValue, waitForCompletion: false)
            
            stick.runAction(SKAction.sequence([SKAction.waitForDuration(0.2), action, playFall]), completion: {[unowned self] () -> Void in
                self.heroGo(self.checkPass())
            })
        }
    }
    
    func start() {
        loadBackground()
        loadScoreBackground()
        loadScore()
        loadTip()
 
        leftStack = loadStacks(false, startLeftPoint: playAbleRect.origin.x)
        self.removeMidTouch(false, left:true)
        loadHero()
 
        let maxGap = Int(playAbleRect.width - StackMaxWidth - (leftStack?.frame.size.width)!)
        let gap = CGFloat(randomInRange(StackGapMinWidth...maxGap))
        rightStack = loadStacks(false, startLeftPoint: nextLeftStartX + gap)
        
        gameOver = false
    }
    
    private func checkPass() -> Bool {
        let stick = childNodeWithName(StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode

        let rightPoint = DefinedScreenWidth / 2 + stick.position.x + self.stickHeight
        
        guard rightPoint < self.nextLeftStartX else {
            return false
        }
        
        guard (CGRectIntersectsRect((leftStack?.frame)!, stick.frame) && CGRectIntersectsRect((rightStack?.frame)!, stick.frame)) else {
            return false
        }
        
        self.checkTouchMidStack()
        
        return true
    }
    
    private func checkTouchMidStack() {
        let stick = childNodeWithName(StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        let stackMid = rightStack!.childNodeWithName(StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        
        let newPoint = stackMid.convertPoint(CGPointMake(-10, 10), toNode: self)
        
        if ((stick.position.x + self.stickHeight) >= newPoint.x  && (stick.position.x + self.stickHeight) <= newPoint.x + 20) {
            loadPerfect()
            self.runAction(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickTouchMidAudioName.rawValue, waitForCompletion: false))
            score++
        }
 
    }
    
    private func removeMidTouch(animate:Bool, left:Bool) {
        let stack = left ? leftStack : rightStack
        let mid = stack!.childNodeWithName(StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        if (animate) {
            mid.runAction(SKAction.fadeAlphaTo(0, duration: 0.3))
        }
        else {
            mid.removeFromParent()
        }
    }
    
    private func heroGo(pass:Bool) {
        let hero = childNodeWithName(StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        
        guard pass else {
            let stick = childNodeWithName(StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
            
            let dis:CGFloat = stick.position.x + self.stickHeight
            let disGap = nextLeftStartX - (DefinedScreenWidth / 2 - abs(hero.position.x)) - (rightStack?.frame.size.width)! / 2

            let move = SKAction.moveToX(dis, duration: NSTimeInterval(abs(disGap / HeroSpeed)))

            hero.runAction(walkAction, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
            hero.runAction(move, completion: {[unowned self] () -> Void in
                stick.runAction(SKAction.rotateToAngle(CGFloat(-M_PI), duration: 0.4))
                
                hero.physicsBody!.affectedByGravity = true
                hero.runAction(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.DeadAudioName.rawValue, waitForCompletion: false))
                hero.removeActionForKey(StickHeroGameSceneActionKey.WalkAction.rawValue)
                self.runAction(SKAction.waitForDuration(2), completion: {[unowned self] () -> Void in
                    self.gameOver = true
                })
            })

            return
        }
        
        let dis:CGFloat = -DefinedScreenWidth / 2 + nextLeftStartX - hero.size.width / 2 - 20
        let disGap = nextLeftStartX - (DefinedScreenWidth / 2 - abs(hero.position.x)) - (rightStack?.frame.size.width)! / 2
        
        let move = SKAction.moveToX(dis, duration: NSTimeInterval(abs(disGap / HeroSpeed)))
 
        hero.runAction(walkAction, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
        hero.runAction(move) { [unowned self]() -> Void in
            self.score++
            
            hero.runAction(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.VictoryAudioName.rawValue, waitForCompletion: false))
            hero.removeActionForKey(StickHeroGameSceneActionKey.WalkAction.rawValue)
            self.moveStackAndCreateNew()
        }
    }
    
    private func moveStackAndCreateNew() {
        let action = SKAction.moveBy(CGVectorMake(-nextLeftStartX + (rightStack?.frame.size.width)! + playAbleRect.origin.x - 2, 0), duration: 0.3)
        rightStack?.runAction(action)
        self.removeMidTouch(true, left:false)

        let hero = childNodeWithName(StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let stick = childNodeWithName(StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        
        hero.runAction(action)
        stick.runAction(SKAction.group([SKAction.moveBy(CGVectorMake(-DefinedScreenWidth, 0), duration: 0.5), SKAction.fadeAlphaTo(0, duration: 0.3)])) { () -> Void in
            stick.removeFromParent()
        }
        
        leftStack?.runAction(SKAction.moveBy(CGVectorMake(-DefinedScreenWidth, 0), duration: 0.5), completion: {[unowned self] () -> Void in
            self.leftStack?.removeFromParent()
            
            let maxGap = Int(self.playAbleRect.width - (self.rightStack?.frame.size.width)! - self.StackMaxWidth)
            let gap = CGFloat(randomInRange(self.StackGapMinWidth...maxGap))
            
            self.leftStack = self.rightStack
            self.rightStack = self.loadStacks(true, startLeftPoint:self.playAbleRect.origin.x + (self.rightStack?.frame.size.width)! + gap)
        })
    }
  
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - 加载场景
private extension StickHeroGameScene {
    func loadBackground() {
        guard let _ = childNodeWithName("background") as! SKSpriteNode? else {
            let texture = SKTexture(image: UIImage(named: "stick_background.jpg")!)
            let node = SKSpriteNode(texture: texture)
            node.size = texture.size()
            node.zPosition = StickHeroGameSceneZposition.BackgroundZposition.rawValue
            self.physicsWorld.gravity = CGVectorMake(0, gravity)
            
            addChild(node)
            return
        }
    }
    
    func loadScore() {
        let scoreBand = SKLabelNode(fontNamed: "Arial")
        scoreBand.name = StickHeroGameSceneChildName.ScoreName.rawValue
        scoreBand.text = "0"
        scoreBand.position = CGPointMake(0, DefinedScreenHeight / 2 - 200)
        scoreBand.fontColor = SKColor.whiteColor()
        scoreBand.fontSize = 100
        scoreBand.zPosition = StickHeroGameSceneZposition.ScoreZposition.rawValue
        scoreBand.horizontalAlignmentMode = .Center
        
        addChild(scoreBand)
    }
    
    func loadScoreBackground() {
        let back = SKShapeNode(rect: CGRectMake(0-120, 1024-200-30, 240, 140), cornerRadius: 20)
        back.zPosition = StickHeroGameSceneZposition.ScoreBackgroundZposition.rawValue
        back.fillColor = SKColor.blackColor().colorWithAlphaComponent(0.3)
        back.strokeColor = SKColor.blackColor().colorWithAlphaComponent(0.3)
        addChild(back)
    }
    
    func loadHero() {
        let hero = SKSpriteNode(imageNamed: "human1")
        hero.name = StickHeroGameSceneChildName.HeroName.rawValue
        hero.position = CGPointMake(-DefinedScreenWidth / 2 + nextLeftStartX - hero.size.width / 2 - 20, -DefinedScreenHeight / 2 + StackHeight + hero.size.height / 2 - 4)
        hero.zPosition = StickHeroGameSceneZposition.HeroZposition.rawValue
        hero.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(16, 18))
        hero.physicsBody?.affectedByGravity = false
        hero.physicsBody?.allowsRotation = false
        
        addChild(hero)
    }
    
    func loadTip() {
        let tip = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        tip.name = StickHeroGameSceneChildName.TipName.rawValue
        tip.text = "将手放在屏幕使竿变长"
        tip.position = CGPointMake(0, DefinedScreenHeight / 2 - 350)
        tip.fontColor = SKColor.blackColor()
        tip.fontSize = 52
        tip.zPosition = StickHeroGameSceneZposition.TipZposition.rawValue
        tip.horizontalAlignmentMode = .Center
    
        addChild(tip)
    }
    
    func loadPerfect() {
        defer {
            let perfect = childNodeWithName(StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode?
            let sequence = SKAction.sequence([SKAction.fadeAlphaTo(1, duration: 0.3), SKAction.fadeAlphaTo(0, duration: 0.3)])
            let scale = SKAction.sequence([SKAction.scaleTo(1.4, duration: 0.3), SKAction.scaleTo(1, duration: 0.3)])
            perfect!.runAction(SKAction.group([sequence, scale]))
        }

        guard let _ = childNodeWithName(StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode? else {
            let perfect = SKLabelNode(fontNamed: "Arial")
            perfect.text = "Perfect +1"
            perfect.name = StickHeroGameSceneChildName.PerfectName.rawValue
            perfect.position = CGPointMake(0, -100)
            perfect.fontColor = SKColor.blackColor()
            perfect.fontSize = 50
            perfect.zPosition = StickHeroGameSceneZposition.PerfectZposition.rawValue
            perfect.horizontalAlignmentMode = .Center
            perfect.alpha = 0
            
            addChild(perfect)
            
            return
        }
       
    }
    
    func loadStick() -> SKSpriteNode {
        let hero = childNodeWithName(StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode

        let stick = SKSpriteNode(color: SKColor.blackColor(), size: CGSizeMake(12, 1))
        stick.zPosition = StickHeroGameSceneZposition.StickZposition.rawValue
        stick.name = StickHeroGameSceneChildName.StickName.rawValue
        stick.anchorPoint = CGPointMake(0.5, 0);
        stick.position = CGPointMake(hero.position.x + hero.size.width / 2 + 18, hero.position.y - hero.size.height / 2)
        addChild(stick)
        
        return stick
    }
    
    func loadStacks(animate: Bool, startLeftPoint: CGFloat) -> SKShapeNode {
        let max:Int = Int(StackMaxWidth / 10)
        let min:Int = Int(StackMinWidth / 10)
        let width:CGFloat = CGFloat(randomInRange(min...max) * 10)
        let height:CGFloat = StackHeight
        let stack = SKShapeNode(rectOfSize: CGSizeMake(width, height))
        stack.fillColor = SKColor.blackColor()
        stack.strokeColor = SKColor.blackColor()
        stack.zPosition = StickHeroGameSceneZposition.StackZposition.rawValue
        stack.name = StickHeroGameSceneChildName.StackName.rawValue
 
        if (animate) {
            stack.position = CGPointMake(DefinedScreenWidth / 2, -DefinedScreenHeight / 2 + height / 2)
            
            stack.runAction(SKAction.moveToX(-DefinedScreenWidth / 2 + width / 2 + startLeftPoint, duration: 0.3), completion: {[unowned self] () -> Void in
                self.isBegin = false
                self.isEnd = false
            })
            
        }
        else {
            stack.position = CGPointMake(-DefinedScreenWidth / 2 + width / 2 + startLeftPoint, -DefinedScreenHeight / 2 + height / 2)
        }
        addChild(stack)
        
        let mid = SKShapeNode(rectOfSize: CGSizeMake(20, 20))
        mid.fillColor = SKColor.redColor()
        mid.strokeColor = SKColor.redColor()
        mid.zPosition = StickHeroGameSceneZposition.StackMidZposition.rawValue
        mid.name = StickHeroGameSceneChildName.StackMidName.rawValue
        mid.position = CGPointMake(0, height / 2 - 20 / 2)
        stack.addChild(mid)
        
        nextLeftStartX = width + startLeftPoint
        
        return stack
    }
    
}
