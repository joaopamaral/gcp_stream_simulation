import unittest

from stream_simulate import StreamSimulate


class TestStreamSimulate(unittest.TestCase):

    def test_schema(self):
        expected_fields = {"vendorid", "tpep_pickup_datetime", "tpep_dropoff_datetime",
                           "passenger_count", "trip_distance", "ratecodeid", "store_and_fwd_flag",
                           "pulocationid", "dolocationid", "payment_type", "fare_amount",
                           "mta_tax", "tip_amount", "tolls_amount", "improvement_surcharge",
                           "total_amount", "congestion_surcharge", "extra"}
        data = StreamSimulate().get_data(0)
        for row in data:
            for key in row.keys():
                self.assertIn(key, expected_fields)


if __name__ == '__main__':
    unittest.main()
