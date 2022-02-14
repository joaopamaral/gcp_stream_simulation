import argparse
import json
from typing import List, Dict
import time

from sodapy import Socrata
from google.cloud import pubsub_v1

project_id = "americanas-joao-test"
topic_id = "nyc_2019_taxi_trips"


class StreamSimulate:
    def __init__(self, domain='data.cityofnewyork.us', dataset_id='2upf-qytp', limit=1, timeout=10, request_time=1):
        self.domain = domain
        self.dataset_id = dataset_id
        self.client = Socrata(self.domain, app_token=None)
        self.limit = limit
        self.timeout = timeout if timeout else float('inf')
        self.request_time = request_time

    def run(self):
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path(project_id, topic_id)
        start = time.time()

        i = 0
        while True:
            print(f"Writing data {self.limit * i}-{self.limit + (self.limit * i)}")
            data = self.get_data(self.limit * i)
            for row in data:
                data = json.dumps(row).encode("utf-8")
                publisher.publish(topic_path, data)
            if not data or (time.time() - start) > self.timeout:
                break
            time.sleep(self.request_time)
            i += 1

        print("The stream simulation is over!")

    def get_data(self, offset) -> List[Dict]:
        return self.client.get(self.dataset_id, limit=self.limit, offset=offset)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Stream Simulate - simulate streaming behaviour for Socrata Open '
                                                 'Data API')
    parser.add_argument('-d', '--domain', help='Data domain', required=False, default='data.cityofnewyork.us')
    parser.add_argument('-ds', '--dataset_id', help='Dataset identifier', required=False, default='2upf-qytp')
    parser.add_argument('-l', '--limit', help='Number of rows returned in each interaction (default 10000)', required=False,
                        default=100,  type=int)
    parser.add_argument('-t', '--timeout', help='Timeout in seconds to stop the simulator (default inf)', required=False,
                        default=None, type=int)
    parser.add_argument('-rt', '--request_time', help='Time in seconds between each request (default 1 sec)', required=False,
                        default=1, type=int)
    args = vars(parser.parse_args())

    StreamSimulate(**args).run()
