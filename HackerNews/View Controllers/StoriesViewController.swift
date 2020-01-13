
import Cocoa
import PromiseKit

class StoriesViewController: NSViewController {

    // MARK: - IBOutlets

    @IBOutlet var storyScrollView: NSScrollView!
    @IBOutlet var storyTableView: NSTableView!
    @IBOutlet var progressView: ProgressView!
    @IBOutlet var storySearchView: StorySearchView!

    // MARK: - Parent View Controller

    var splitViewController: SplitViewController {
        parent as! SplitViewController
    }

    // MARK: - Properties

    var stories: [Storyable] = [] {
        didSet {
            storyTableView.reloadData()
        }
    }

    var selectedStory: Story? {
        get {
            splitViewController.currentStory
        }
        set {
            splitViewController.currentStory = newValue
        }
    }

    var storyLoadProgress: Progress? {
        didSet {
            progressView.progress = storyLoadProgress
        }
    }

    // MARK: - Methods

    func loadAndDisplayStories(count: Int = 10) {
        storyTableView.isHidden = true

        storyLoadProgress = Progress(totalUnitCount: 100)
        storyLoadProgress?.becomeCurrent(withPendingUnitCount: 100)
        firstly {
            HackerNewsAPI.topStories(count: count)
        }.done { stories in
            self.storyLoadProgress?.resignCurrent()
            self.storyLoadProgress = nil
            self.stories = stories
            self.storyTableView.reloadData()
            self.storyTableView.isHidden = false
        }.catch { error in
            print(error)
        }
    }

    func initializeInterface() {
        progressView.labelText = "Loading Stories..."
        storyScrollView.automaticallyAdjustsContentInsets = false
    }

    func updateContentInsets() {
        let window = view.window!
        let contentLayoutRect = window.contentLayoutRect
        let storySearchViewHeight = storySearchView.frame.height
        let topInset = (window.contentView!.frame.size.height - contentLayoutRect.height) + storySearchViewHeight
        storyScrollView.contentInsets = NSEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeInterface()
        loadAndDisplayStories()
    }

    var contentLayoutRectObservation: NSKeyValueObservation?

    override func viewWillAppear() {
        super.viewWillAppear()
        contentLayoutRectObservation = view.window!.observe(\.contentLayoutRect) { _, _ in
            self.updateContentInsets()
        }
    }

    var storySearchViewConstraint: NSLayoutConstraint?

    override func updateViewConstraints() {
        if storySearchViewConstraint == nil, let contentLayoutGuide = view.window?.contentLayoutGuide as? NSLayoutGuide {
            let contentTopAnchor = contentLayoutGuide.topAnchor
            storySearchViewConstraint = storySearchView.topAnchor.constraint(equalTo: contentTopAnchor)
            storySearchViewConstraint?.isActive = true
        }
        super.updateViewConstraints()
    }
}

// MARK: - StoryCellViewDelegate

extension StoriesViewController: StoryCellViewDelegate {

    func formattedTitle(for story: Storyable?) -> String {
        guard let story = story else {
            return ""
        }
        return story.title
    }

    func formattedScore(for story: Storyable?) -> String {
        guard let story = story, !(story is Job) else {
            return ""
        }
        return String(story.score)
    }

    func formattedCommentCount(for story: Storyable?) -> String {
        guard let story = story as? Story else {
            return ""
        }
        return String(story.commentCount)
    }

    func isURLHidden(for story: Storyable?) -> Bool {
        guard let story = story as? Story else {
            return true
        }
        return story.url == nil
    }

    func formattedURL(for story: Storyable?) -> String {
        guard let story = story as? Story, let urlHost = story.url?.host else {
            return ""
        }
        return urlHost
    }

    func formattedDate(for story: Storyable?) -> String {
        guard let story = story else {
            return ""
        }
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.formattingContext = .standalone
        dateFormatter.dateTimeStyle = .named
        return dateFormatter.localizedString(for: story.time, relativeTo: Date())
    }

    func openURL(for story: Storyable?) {
        guard let story = story as? Story, let url = story.url else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - StorySearchViewDelegate

extension StoriesViewController: StorySearchViewDelegate {

    func reloadStories(count: Int) {
        loadAndDisplayStories(count: count)
    }
}

// MARK: - NSTableViewDataSource

extension StoriesViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        stories.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        stories[row]
    }
}

// MARK: - NSTableViewDelegate

extension StoriesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // objectValue is automatically populated
        tableView.makeView(withIdentifier: .storyCellView, owner: self)
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView.makeView(withIdentifier: .storyRowView, owner: self) as? StoryRowView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedStory = stories[storyTableView.selectedRow] as? Story
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {

    static let storyCellView = NSUserInterfaceItemIdentifier("StoryCellView")
    static let storyRowView = NSUserInterfaceItemIdentifier("StoryRowView")
}
