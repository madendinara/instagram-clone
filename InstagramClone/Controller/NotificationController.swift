//
//  NotificationController.swift
//  InstagramClone
//
//  Created by Динара Зиманова on 11/17/21.
//

import UIKit

class NotificationController: UITableViewController {
    
    // MARK: - Properties
    var notifications = [Notification]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        getNotifications()
    }
    
    // MARK: - Methods
    func configureView() {
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        navigationItem.title = "Notifications"
        view.backgroundColor = .white
        
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refresher
    }
    
    func getNotifications() {
        NotificationsService.getNotifications { notifications in
            self.notifications = notifications
            self.checkIfUserIsFollowed()
        }
    }
    
    func checkIfUserIsFollowed() {
        notifications.forEach { notification in
            UserService.checkIfUserIsFollowed(uid: notification.uid) { isFollowed in
                if let index = self.notifications.firstIndex(where: { $0.uid == notification.uid }) {
                    self.notifications[index].isFollowed = isFollowed
                    
                }
                
                
            }
            
        }
    }
    
    @objc func refreshNotifications(){
        notifications.removeAll()
        getNotifications()
        self.tableView.refreshControl?.endRefreshing()
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension NotificationController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        cell.viewModel = NotificationViewModel(notification: notifications[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoader(true)
        let uid = notifications[indexPath.row].uid
        
        UserService.fetchUser(withUid: uid) { user in
            let controller = ProfileController(user: user)
            self.navigationController?.pushViewController(controller, animated: true)
            self.showLoader(false)
        }
    }
    
}

extension NotificationController: NotificationCellDelegate {
    func cell(_ cell: NotificationCell, wantsToFollow userUid: String) {
        showLoader(true)
        UserService.follow(uid: userUid) { _ in
            self.showLoader(false)
            cell.viewModel?.notification.isFollowed.toggle()
            self.getNotifications()
            self.tableView.reloadData()
        }
    }
    
    func cell(_ cell: NotificationCell, wantsToOpen postId: String) {
        showLoader(true)
        PostService.getPost(forPost: postId) { post in
            let controller = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
            controller.post = post
            self.navigationController?.pushViewController(controller, animated: true)
            self.showLoader(false)
        }
        
    }
    
    func cell(_ cell: NotificationCell, wantsToUnfollow userUid: String) {
        showLoader(true)
        UserService.unfollow(uid: userUid) { _ in
            self.showLoader(false)
            cell.viewModel?.notification.isFollowed.toggle()
            self.getNotifications()
            self.tableView.reloadData()
        }
        
    }
    
}
