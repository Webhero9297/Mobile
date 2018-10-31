//
//  TransactionsTableViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit
import SafariServices

private let promptDelay: TimeInterval = 0.6

class TransactionsTableViewController : UITableViewController, Subscriber, Trackable {

    //MARK: - Public
    init(currency: CurrencyDef, walletManager: WalletManager, didSelectTransaction: @escaping ([Transaction], Int) -> Void) {
        self.currency = currency
        self.walletManager = walletManager
        self.didSelectTransaction = didSelectTransaction
        self.isBtcSwapped = Store.state.isBtcSwapped
        super.init(nibName: nil, bundle: nil)
    }

    let didSelectTransaction: ([Transaction], Int) -> Void

    var filters: [TransactionFilter] = [] {
        didSet {
            transactions = filters.reduce(allTransactions, { $0.filter($1) })
            tableView.reloadData()
        }
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let currency: CurrencyDef
    
    private let headerCellIdentifier = "HeaderCellIdentifier"
    private let transactionCellIdentifier = "TransactionCellIdentifier"
    private var transactions: [Transaction] = []
    private var allTransactions: [Transaction] = [] {
        didSet { transactions = allTransactions }
    }
    private var isBtcSwapped: Bool {
        didSet { reload() }
    }
    private var rate: Rate? {
        didSet { reload() }
    }
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    //TODO:BCH replace with recommend rescan / tx failed prompt
    private var currentPrompt: Prompt? {
        didSet {
            if currentPrompt != nil && oldValue == nil {
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            } else if currentPrompt == nil && oldValue != nil {
                tableView.beginUpdates()
                tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            }
        }
    }
    private var hasExtraSection: Bool {
        return (currentPrompt != nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TxListCell.self, forCellReuseIdentifier: transactionCellIdentifier)
        tableView.register(TxListCell.self, forCellReuseIdentifier: headerCellIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.TransactionDetails.emptyMessage
        
        //setContentInset()

        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        Store.subscribe(self,
                        selector: { $0.isBtcSwapped != $1.isBtcSwapped },
                        callback: { self.isBtcSwapped = $0.isBtcSwapped })
        Store.subscribe(self,
                        selector: { $0[self.currency]?.currentRate != $1[self.currency]?.currentRate},
                        callback: {
                            self.rate = $0[self.currency]?.currentRate
        })
        Store.subscribe(self, selector: { $0[self.currency]?.maxDigits != $1[self.currency]?.maxDigits }, callback: {_ in
            self.reload()
        })
        
        Store.subscribe(self, name: .txMemoUpdated(""), callback: {
            guard let trigger = $0 else { return }
            if case .txMemoUpdated(let txHash) = trigger {
                self.reload(txHash: txHash)
            }
        })
        
        Store.subscribe(self, selector: {
            guard let oldTransactions = $0[self.currency]?.transactions else { return false }
            guard let newTransactions = $1[self.currency]?.transactions else { return false }
            return oldTransactions != newTransactions },
                        callback: { state in
                            self.allTransactions = state[self.currency]?.transactions ?? [Transaction]()
                            self.reload()
        })
    }

    private func reload(txHash: String) {
        self.transactions.enumerated().forEach { i, tx in
            if tx.hash == txHash {
                DispatchQueue.main.async {
                    self.tableView.reload(row: i, section: self.hasExtraSection ? 1 : 0)
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return hasExtraSection ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasExtraSection && section == 0 {
            return 1
        } else {
            return transactions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasExtraSection && indexPath.section == 0 {
            return headerCell(tableView: tableView, indexPath: indexPath)
        } else {
            return transactionCell(tableView: tableView, indexPath: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasExtraSection && section == 1 {
            return C.padding[2]
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if hasExtraSection && section == 1 {
            return UIView(color: .clear)
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hasExtraSection && indexPath.section == 0 { return }
        didSelectTransaction(transactions, indexPath.row)
    }

    private func reload() {
        tableView.reloadData()
        if transactions.count == 0 {
            if emptyMessage.superview == nil {
                tableView.addSubview(emptyMessage)
                emptyMessage.constrain([
                    emptyMessage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                    emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -0), //TODO:UI
                    emptyMessage.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[2]) ])
            }
        } else {
            emptyMessage.removeFromSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Cell Builders
extension TransactionsTableViewController {

    private func headerCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath)
        if let containerCell = cell as? TxListCell {
            if let prompt = currentPrompt {
                containerCell.contentView.addSubview(prompt)
                prompt.constrain(toSuperviewEdges: nil)
            }
        }
        return cell
    }

    private func transactionCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: transactionCellIdentifier, for: indexPath) as! TxListCell
        let rate = self.rate ?? Rate.empty
        let viewModel = TxListViewModel(tx: transactions[indexPath.row])
        cell.setTransaction(viewModel,
                            isBtcSwapped: isBtcSwapped,
                            rate: rate,
                            maxDigits: currency.state?.maxDigits ?? currency.commonUnit.decimals,
                            isSyncing: currency.state?.syncState != .success)
        return cell
    }
}
