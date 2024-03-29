//
//  SearchViewController.swift
//  PodcastApp
//
//  Created by Ben Scheirman on 3/7/19.
//  Copyright © 2019 NSScreencast. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController, UISearchResultsUpdating {

    var recommendedPodcasts: [SearchResult] = []
    var results: [SearchResult] = []

    private let dataManager = PodcastDataManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorInset = .zero
        tableView.backgroundColor = Theme.Colors.gray4
        tableView.separatorColor = Theme.Colors.gray3

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false

        loadRecommendedPodcasts()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func loadRecommendedPodcasts() {
        dataManager.recommendedPodcasts { result in
            switch result {
            case .success(let podcastResults):
                self.recommendedPodcasts = podcastResults
                self.results = self.recommendedPodcasts
                self.tableView.reloadData()

            case .failure(let error):
                print("Error loading recommended podcasts: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let term = searchController.searchBar.text ?? ""
        if term.isEmpty {
            resetToRecommendedPodcasts()
            return
        }

        dataManager.search(for: term) { result in
            switch result {
            case .success(let searchResults):
                self.results = searchResults
                self.tableView.reloadData()

            case .failure(let error):
                print("Error searching podcasts: \(error.localizedDescription)")
            }
        }
    }

    private func resetToRecommendedPodcasts() {
        results = recommendedPodcasts
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SearchResultCell = tableView.dequeueReusableCell(for: indexPath)
        let searchResult = results[indexPath.row]
        cell.configure(with: searchResult)
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results[indexPath.row]

        if let feed = result.feedURL {
            showPodcast(with: feed)
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            dataManager.lookup(podcastID: result.id) { result in
                switch result {
                case .success(let podcast):
                    if let feed = podcast?.feedURL {
                        self.showPodcast(with: feed)
                    } else {
                        print("Podcast not found")
                    }
                case .failure(let error):
                    print("Error loading podcast: \(error.localizedDescription)")
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    private func showPodcast(with feedURL: URL) {
        let detailVC = UIStoryboard(name: "PodcastDetail", bundle: nil).instantiateInitialViewController() as! PodcastDetailViewController
        detailVC.feedURL = feedURL
        show(detailVC, sender: self)
    }
}
