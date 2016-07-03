import UIKit
import PlaygroundSupport

final class LabelViewController: UIViewController {
    
    private let longText = "Heirloom banjo readymade kogi, cold-pressed YOLO raw denim Echo Park fashion axe 8-bit kale chips occupy. Meh ugh farm-to-table Pinterest fingerstache 8-bit. +1 hella PBR sartorial blog Intelligentsia, XOXO post-ironic slow-carb taxidermy Vice pop-up Neutra. McSweeney's vegan listicle put a bird on it fanny pack. Kickstarter narwhal Banksy, Marfa hashtag retro polaroid VHS farm-to-table Williamsburg stumptown twee. Banjo Schlitz Williamsburg yr listicle lumbersexual. Retro synth Wes Anderson, Williamsburg brunch raw denim quinoa flexitarian hoodie kale chips."
    
    private lazy var label1: UILabel = {
        let label = UILabel()
        label.text = self.longText
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
        label.numberOfLines = 2
        label.textAlignment = .justified
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var label2: TruncatingLabel = {
        let label = TruncatingLabel()
        label.text = self.longText
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
        label.numberOfLines = 2
        label.textAlignment = .justified
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white()
        
        label1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label1)
        label1.setContentHuggingPriority(251, for: .horizontal)
        label1.setContentHuggingPriority(251, for: .vertical)
        
        label2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label2)
        label2.setContentHuggingPriority(251, for: .horizontal)
        label2.setContentHuggingPriority(251, for: .vertical)
        
        NSLayoutConstraint.activate([
            label1.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 8),
            label1.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            view.layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: label1.trailingAnchor),
            label2.leadingAnchor.constraint(equalTo: label1.leadingAnchor),
            label2.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 42),
            view.layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: label2.trailingAnchor),
            ])
    }
    
    private var timer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(noteDemoTick), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
        label1.preferredMaxLayoutWidth = width
        label2.preferredMaxLayoutWidth = width
        
        view.layoutIfNeeded()
    }
    
    // MARK: -
    
    private var demoTick = 0
    
    @IBAction func noteDemoTick() {
        demoTick += 1
        if (demoTick % 2) != 0 {
            view.tintAdjustmentMode = .automatic
            label2.toggleTruncation()
        } else {
            view.tintAdjustmentMode = .dimmed
        }
    }
    
}

PlaygroundPage.current.liveView = LabelViewController()
