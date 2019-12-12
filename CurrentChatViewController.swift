//
//  CurrentChatViewController.swift
//  SPNChat
//
//  Created by Vimal Das on 06/08/19.
//  Copyright © 2019 Spericorn Technology. All rights reserved.
//

import UIKit

class CurrentChatViewController: UIViewController {
    /// connection to tableview.
    @IBOutlet weak var tableView: UITableView!
    /// connection to search field.
    @IBOutlet weak var searchTextfield: CustomTextField!
    /// connection to the image which responds to thst state change in app.
    @IBOutlet weak var emptyStateImageview: UIImageView!
    /// connection to the title which responds to thst state change in app.
    @IBOutlet weak var emptyChatTitleLabel: UILabel!
    /// connection to the subtitle which responds to thst state change in app.
    @IBOutlet weak var emptyChatSubTitleLabel: UILabel!
    /// connection to the searcgView for hide and show animation.
    @IBOutlet weak var searchView: UIView!
    
    /// connection to the main navigation controller in app.
    var navigation: SPNChatNavigationController?
    /// array which holds the result of a search.
    var filteredTableData = [SocketModel]()
    /// chat list details array
    var chatlist: [SocketModel] = []
    /// keep track of all clients who are cuttently typing.
    var typingChatUsers: [String] = []
    /// refresh control to show when  loading.
    var refreshControl: UIRefreshControl!
    /// search keyword.
    var searchText: String = ""
    /// keep track of  the table initial loading animation.
    var finishedLoadingInitialTableCells = false
    /// keep track and handle the state change in screen.
    var emptyStateCheck: EmptyStates = .success {
        didSet {
            self.emptyStateImageview.image = emptyStateCheck.image
            self.emptyChatTitleLabel.text = emptyStateCheck.title
            self.emptyChatSubTitleLabel.text = emptyStateCheck.subTitle
            self.handleSearchDependingOnEmptyState()
        }
    }
    
    // MARK:- ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigation = self.navigationController as? SPNChatNavigationController
        navigation?.shouldHideNavigationBar = false
        searchTextfield.delegate = self
        searchTextfield.addPaddingLeftIcon(#imageLiteral(resourceName: "ic_search-1"), padding: 10)
        searchView.addSmallShadow()
        
        EmptyStateHandler.shared.emptyStateDelegate = self
        self.tableView.contentInset.bottom = 10
        emptyStateCheck = .success
        addRefreshControl()
    }
    
    // MARK:- viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigation?.navigationBar.topItem?.title = StringConstants.Titles.currentChat
        navigation?.addLeftSideLogo()
        finishedLoadingInitialTableCells = false
        self.chatlist.removeAll()
        self.tableView.reloadData()
        refresh()
        SocketHelper.shared.delegate = self
    }
    
    // MARK:- viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigation?.removeLeftSideLogo()
        self.view.endEditing(true)
    }
    
    /// handle search depending on emptyState with animation.
    func handleSearchDependingOnEmptyState() {
        if emptyStateCheck == .success || emptyStateCheck == .noSearchResults {
            if searchTextfield.transform != .identity {
                UIView.animate(withDuration: 0.3) {
                    self.searchTextfield.transform = .identity
                    self.searchTextfield.alpha = 1
                    self.searchView.alpha = 1
                }
            }
          
        } else {
            if searchTextfield.transform == .identity {
                UIView.animate(withDuration: 0.3) {
                    self.searchTextfield.transform = CGAffineTransform(translationX: 0, y: 50)
                    self.searchTextfield.alpha = 0
                    self.searchView.alpha = 0
                }
            }
        }
    }
    
    /// adding refresh control.
    func addRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl.tintColor = AppColor.baseColor
        tableView.addSubview(refreshControl)
    }
    
    /// load chat list.
    @objc func refresh() {
        self.getOngoingChatList()
    }
    
    /// get ongoing chatList
    func getOngoingChatList() {
        self.tableView.isUserInteractionEnabled = false
        let params = [Constants.Api.keys.onGoingChatList.agent       : AgentUser.currentUser.agentId ?? "",
                      Constants.Api.keys.onGoingChatList.page        : Constants.currentChatPageNumber,
                      Constants.Api.keys.onGoingChatList.pageLimit   : Constants.pageLimit,
                      Constants.Api.keys.onGoingChatList.isCompleted : Constants.isCurrentChatPageLoadingCompleted,
                      Constants.Api.keys.onGoingChatList.businessUid : AgentUser.currentUser.agentBusinessUid] as [String : Any]
        
        AlamofireServiceManager.shared.getOngoingChatList(parameters: params) { (result) in
            
            switch result {
            case .success(let data):
                self.tableView.isUserInteractionEnabled = true
                if let jsonArray = data[Constants.Api.keys.onGoingChatList.responseKey] as? [NSDictionary],
                    jsonArray.count == 0 {
                    self.emptyStateCheck = .emptyData
                } else {
                    self.emptyStateCheck = .success
                    self.handleChatListData(data: data)
                }
                
            case .failure(let error):
                switch error {
                case .apiError(_):
                    self.tableView.isUserInteractionEnabled = true
                    self.emptyStateCheck = .apiError
                    
                case .noData(_):
                    self.tableView.isUserInteractionEnabled = true
                        self.emptyStateCheck = .apiError
                }
            }
            
            self.refreshControl.endRefreshing()
        }
    }
    
    /// handle the received chatlist data
    func handleChatListData(data: NSDictionary) {
        self.chatlist.removeAll()
        self.tableView.reloadData()
        if let jsonArray = data[Constants.Api.keys.onGoingChatList.responseKey] as? [NSDictionary] {
            for dict in jsonArray {
                let socketData = SocketModel()
                self.chatlist.append(socketData.initWith(dict: dict))
            }
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
}

// MARK:- UITableViewDataSource
extension CurrentChatViewController: UITableViewDataSource {
    // MARK: numberOfSections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // MARK: numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !(searchText.isEmpty) {
            return filteredTableData.count
        } else {
            return chatlist.count
        }
    }
    // MARK: cellForRowAtIndexpath
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.keys.currentChatTableViewCell, for: indexPath) as! CurrentChatTableViewCell
        
        if !(searchText.isEmpty) {
            cell.fillFields(with: filteredTableData[indexPath.row])
            cell.userNamelabel.textColor = .gray
            cell.lastMessageLabel.textColor = .gray
            cell.userNamelabel.attributedText = filteredTableData[indexPath.row].custFullName.changeColor(of: searchText)
            if filteredTableData[indexPath.row].fileLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cell.lastMessageLabel.attributedText = filteredTableData[indexPath.row].lastMessage.changeColor(of: searchText)
            }
          
        } else {
            cell.userNamelabel.attributedText = nil
            cell.lastMessageLabel.attributedText = nil
            cell.lastMessageLabel.textColor = .gray
            cell.fillFields(with: chatlist[indexPath.row])
            cell.userNamelabel.text = chatlist[indexPath.row].custFullName
            cell.userNamelabel.textColor = AppColor.titleBlackColor
            cell.userNamelabel.font = UIFont(name: Constants.Font.regularName, size: Constants.Font.regularSize)
        }
        return cell
    }
    // MARK: willDisplayCell
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        var lastInitialDisplayableCell = false
        
        if chatlist.count > 0 && !finishedLoadingInitialTableCells {
            if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
                let lastIndexPath = indexPathsForVisibleRows.last, lastIndexPath.row == indexPath.row {
                lastInitialDisplayableCell = true
            }
        }
        /// handle animation of first loading.
        if !finishedLoadingInitialTableCells {
            if lastInitialDisplayableCell {
                finishedLoadingInitialTableCells = true
            }
            cell.transform = CGAffineTransform(translationX: 0, y: 85/2)
            cell.alpha = 0
            /// animate the first loading.
            UIView.animate(withDuration: 0.2, delay: 0.05*Double(indexPath.row), options: [.curveEaseInOut], animations: {
                cell.transform = .identity
                cell.alpha = 1
            }, completion: nil)
        }
    }
    
}

// MARK:- UITableViewDelegate
extension CurrentChatViewController: UITableViewDelegate {
    // MARK: didSelectRowAtIndexPath
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: StringConstants.Identifiers.chatBetweenUsersViewController) as! ChatBetweenUsersViewController
        if !(searchText.isEmpty) {
            SocketHelper.shared.currentChatDetails = filteredTableData[indexPath.row]
          
        } else {
            SocketHelper.shared.currentChatDetails = chatlist[indexPath.row]
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK:- UITextFieldDelegate
extension CurrentChatViewController : UITextFieldDelegate {
    // MARK: shouldChangeCharactersInRange
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        searchText = searchTextfield.text!
        if string == "" {
            searchText = String(searchText.dropLast())
        } else {
            searchText += string
        }
        filteredTableData.removeAll(keepingCapacity: false)
        filteredTableData = chatlist.filter({ $0.cusFirstName.localizedCaseInsensitiveContains(searchText) })
        filteredTableData += chatlist.filter({ $0.lastMessage.localizedCaseInsensitiveContains(searchText) && !filteredTableData.contains($0) })
        
        if filteredTableData.count == 0 && !searchText.isEmpty {
            emptyStateCheck = .noSearchResults
          
        } else {
            emptyStateCheck = .success
        }
        
        self.tableView.reloadData()
        
        return true
    }
    
    // MARK: textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    // MARK: textFieldDidEndEditing
    func textFieldDidEndEditing(_ textField: UITextField) {
        if searchTextfield.text! == "" && chatlist.count == 0 {
            emptyStateCheck = .emptyData
          
        } else {
            emptyStateCheck = .success
        }
    }
}

// MARK:- SocketManagerDelegate
extension CurrentChatViewController: SocketManagerDelegate {
    // MARK: didReceiveStatus
    func didReceiveStatus(status: ChatStatus, userDetails: SocketModel) {
        
        switch status {
        /// new user message received event handler
        case .newUser:
            if self.chatlist.count == 0 {
                emptyStateCheck = .success
            }
            if let data = chatlist.filter({ $0.cusUid == userDetails.cusUid }).first,
            let index = chatlist.firstIndex(of: data) {
                self.chatlist.remove(at: index)
                self.chatlist.insert(userDetails, at: 0)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self.tableView.endUpdates()
              
            } else {
                self.chatlist.insert(userDetails, at: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self.tableView.endUpdates()
            }
            
        /// new message received event handler
        case .newMessage:
            if let data = chatlist.filter({ $0.cusUid == userDetails.cusUid }).first,
                let index = chatlist.firstIndex(of: data) {
                if let count = Int(data.unreadMsgCount),
                    userDetails.type == .customer {
                    userDetails.unreadMsgCount = "\(count + 1)"
                }
                self.chatlist.remove(at: index)
                self.chatlist.insert(userDetails, at: 0)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self.tableView.endUpdates()
            } else {
                self.chatlist.insert(userDetails, at: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self.tableView.endUpdates()
            }
            
        /// handling typing status change
        case .isTyping, .stoppedTyping:
            if let visibleCells = tableView.visibleCells as? [CurrentChatTableViewCell] {
                for cell in visibleCells {
                    if cell.custId == userDetails.cusUid {
                        if status == .isTyping {
                            cell.lastMessageLabel.text = "Typing..."
                            
                        } else {
                            cell.lastMessageLabel.text = chatlist.filter({ $0.cusUid == userDetails.cusUid }).first?.lastMessage
                        }
                    }
                }
            }
        
        /// handling online-offline status change
        case .isOnline, .isOffline:
            chatlist.filter({ $0.cusUid == userDetails.cusUid }).first?.onlineOfflineStatus = status == .isOnline ? .online : .offline
        
        /// handling chat picked event
        case .didPickedChat:
            chatlist.filter({ $0.cusUid == userDetails.cusUid }).first?.agentName = userDetails.agentName
            chatlist.filter({ $0.cusUid == userDetails.cusUid }).first?.agentUid = userDetails.agentUid
            if let visibleCells = tableView.visibleCells as? [CurrentChatTableViewCell] {
                for cell in visibleCells {
                    if cell.custId == userDetails.cusUid {
                        if userDetails.agentName == "" {
                            cell.headsetIcon.isHidden = true
                            cell.agentNameLabel.isHidden = true
                          
                        } else {
                            cell.headsetIcon.isHidden = false
                            cell.agentNameLabel.isHidden = false
                            cell.agentNameLabel.text = userDetails.agentName
                        }
                    }
                }
            }
            
        /// handling completed chat event
        case .didCompletedChat:
            if let data = chatlist.filter({ $0.cusUid == userDetails.cusUid }).first,
                let index = chatlist.firstIndex(of: data) {
                self.chatlist.remove(at: index)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.tableView.endUpdates()
            }
            
        default:
            break
        }
    }
    
}

// MARK:- EmptyStateDelegate
extension CurrentChatViewController: EmptyStateDelegate {
    // MARK: didChangeInternetConnectionStatus
    func didChangeInternetConnectionStatus(reachable: Bool) {
        if reachable {
            if searchText.isEmpty && chatlist.count == 0 && filteredTableData.count == 0 {
                refresh()
            }
        } else {
            emptyStateCheck = .noInternetConnection
        }
    }
  
}
