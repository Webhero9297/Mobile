//
//  TxDetailDataSource.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2017-12-20.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class TxDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case amount
        case status
        case memo
        case timestamp
        case address
        case exchangeRate
        case blockHeight
        case transactionId
        case gasPrice
        case gasLimit
        case fee
        case total
        
        var cellType: UITableViewCell.Type {
            switch self {
            case .amount:
                return TxAmountCell.self
            case .status:
                return TxStatusCell.self
            case .memo:
                return TxMemoCell.self
            case .address, .transactionId:
                return TxAddressCell.self
            default:
                return TxLabelCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: TxDetailViewModel
    
    // MARK: - Init
    
    init(viewModel: TxDetailViewModel) {
        self.viewModel = viewModel
        
        // define visible rows and order
        fields = [.amount]
        
        if viewModel.status != .complete && viewModel.status != .invalid {
            fields.append(.status)
        }
        
        fields.append(.timestamp)
        fields.append(.address)
        
        if viewModel.comment != nil      { fields.append(.memo) }
        if viewModel.gasPrice != nil     { fields.append(.gasPrice) }
        if viewModel.gasLimit != nil     { fields.append(.gasLimit) }
        if viewModel.fee != nil          { fields.append(.fee) }
        if viewModel.total != nil        { fields.append(.total) }
        if viewModel.exchangeRate != nil { fields.append(.exchangeRate) }
        
        fields.append(.blockHeight)
        fields.append(.transactionId)
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .status:
            return S.TransactionDetails.statusHeader
        case .memo:
            return S.TransactionDetails.commentsHeader
        case .address:
            return viewModel.addressHeader
        case .exchangeRate:
            return S.TransactionDetails.exchangeRateHeader
        case .blockHeight:
            return S.TransactionDetails.blockHeightLabel
        case .transactionId:
            return S.TransactionDetails.txHashHeader
        case .gasPrice:
            return S.TransactionDetails.gasPriceHeader
        case .gasLimit:
            return S.TransactionDetails.gasLimitHeader
        case .fee:
            return S.TransactionDetails.feeHeader
        case .total:
            return S.TransactionDetails.totalHeader
        default:
            return ""
        }
    }
}

// MARK: -
extension TxDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)
        
        if let rowCell = cell as? TxDetailRowCell {
            rowCell.title = title(forField: field)
        }

        switch field {
        case .amount:
            let amountCell = cell as! TxAmountCell
            amountCell.set(viewModel: viewModel)
    
        case .status:
            let statusCell = cell as! TxStatusCell
            statusCell.set(txInfo: viewModel)
            
        case .memo:
            let memoCell = cell as! TxMemoCell
            memoCell.set(viewModel: viewModel, tableView: tableView)
            
        case .timestamp:
            let labelCell = cell as! TxLabelCell
            labelCell.titleLabel.attributedText = viewModel.timestampHeader
            labelCell.value = viewModel.longTimestamp
            
        case .address:
            let addressCell = cell as! TxAddressCell
            addressCell.set(address: viewModel.displayAddress)
            
        case .exchangeRate:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.exchangeRate ?? ""
            
        case .blockHeight:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.blockHeight
            
        case .transactionId:
            let addressCell = cell as! TxAddressCell
            addressCell.set(address: viewModel.transactionHash)
            
        case .gasPrice:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.gasPrice ?? ""
            
        case .gasLimit:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.gasLimit ?? ""
            
        case .fee:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.fee ?? ""
            
        case .total:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.total ?? ""
        }
        
        return cell

    }
    
}
