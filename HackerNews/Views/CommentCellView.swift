
import Cocoa

@objc protocol CommentCellViewDelegate {

    func formattedAuthor(for comment: Comment?) -> String
    func formattedDate(for comment: Comment?) -> String
    func formattedText(for comment: Comment?) -> String
    func isToggleHidden(for comment: Comment?) -> Bool
    func isToggleExpanded(for comment: Comment?) -> Bool
    func formattedToggleCount(for comment: Comment?) -> String

    func toggle(_ comment: Comment?)
}

class CommentCellView: NSTableCellView {

    // MARK: - IBOutlets

    @IBOutlet var authorLabel: NSTextField!
    @IBOutlet var dateLabel: NSTextField!
    @IBOutlet var textLabel: NSTextField!
    @IBOutlet var toggleButton: NSButton!
    @IBOutlet var toggleCountLabel: NSTextField!

    // MARK: - Delegate

    @IBOutlet var delegate: CommentCellViewDelegate?

    // MARK: - Properties

    // Data source of StoryCellView
    override var objectValue: Any? {
        didSet {
            updateInterface()
        }
    }

    var comment: Comment? {
        objectValue as? Comment
    }

    // MARK: - IBActions

    @IBAction func toggleButton(_ sender: NSButton) {
        delegate?.toggle(comment)
        updateInterface()
    }

    // MARK: - Methods

    func updateInterface() {
        guard let delegate = delegate else {
            return
        }
        textLabel.stringValue = delegate.formattedText(for: comment)
        authorLabel.stringValue = delegate.formattedAuthor(for: comment)
        dateLabel.stringValue = delegate.formattedDate(for: comment)
        toggleButton.isHidden = delegate.isToggleHidden(for: comment)
        toggleButton.state = delegate.isToggleExpanded(for: comment) ? .off : .on
        toggleCountLabel.stringValue = delegate.formattedToggleCount(for: comment)
    }
}
