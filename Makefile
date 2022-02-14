limited_test:
	python src/stream_simulate.py --limit 10 --timeout 5

build_local_image:
	docker build -f docker/Dockerfile -t ame/stream_simulate:latest .

limited_test_docker:
	docker run  ame/stream_simulate:latest python stream_simulate.py --limit 10 --timeout 5

build_submit_cloud_image:
	gcloud builds submit
