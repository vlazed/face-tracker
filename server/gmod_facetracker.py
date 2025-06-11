
import asyncio
import functools
import time
import json

from websockets.exceptions import ConnectionClosed
from websockets.asyncio.server import serve, ServerConnection

import cv2
import numpy as np

import mediapipe as mp
from mediapipe import solutions
from mediapipe.framework.formats import landmark_pb2
import aioprocessing
import matplotlib.pyplot as plt


BaseOptions = mp.tasks.BaseOptions
FaceLandmarker = mp.tasks.vision.FaceLandmarker
FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
FaceLandmarkerResult = mp.tasks.vision.FaceLandmarkerResult
VisionRunningMode = mp.tasks.vision.RunningMode

# You must supply your own face landmarker model for this to work.
# You can get one online pretty easily from Google's mediapipe website
MODEL_PATH = 'face_landmarker.task'

# Didn't test this in different networks, as low latency is key here
SOCKET_HOST = "localhost"

# You must specify the same socket port in the GMod socket file
SOCKET_PORT = "8667"

# How often we stream the data through websockets
# Setting this too high results in backpressure, as
# client websocket cannot receive it as fast as the server
# can send it out
SENDING_FREQUENCY = 2000  # Hz


def draw_landmarks_on_image(rgb_image, detection_result):
    try:
        if detection_result.face_landmarks == []:
            return rgb_image
        else:
            face_landmarks_list = detection_result.face_landmarks
            annotated_image = np.copy(rgb_image)

            # Loop through the detected faces to visualize.
            for idx in range(len(face_landmarks_list)):
                face_landmarks = face_landmarks_list[idx]

                # Draw the face landmarks.
                face_landmarks_proto = landmark_pb2.NormalizedLandmarkList()
                face_landmarks_proto.landmark.extend([
                    landmark_pb2.NormalizedLandmark(x=landmark.x, y=landmark.y, z=landmark.z) for landmark in face_landmarks
                ])

                solutions.drawing_utils.draw_landmarks(
                    image=annotated_image,
                    landmark_list=face_landmarks_proto,
                    connections=mp.solutions.face_mesh.FACEMESH_TESSELATION,
                    landmark_drawing_spec=None,
                    connection_drawing_spec=mp.solutions.drawing_styles
                    .get_default_face_mesh_tesselation_style())
                solutions.drawing_utils.draw_landmarks(
                    image=annotated_image,
                    landmark_list=face_landmarks_proto,
                    connections=mp.solutions.face_mesh.FACEMESH_CONTOURS,
                    landmark_drawing_spec=None,
                    connection_drawing_spec=mp.solutions.drawing_styles
                    .get_default_face_mesh_contours_style())
                solutions.drawing_utils.draw_landmarks(
                    image=annotated_image,
                    landmark_list=face_landmarks_proto,
                    connections=mp.solutions.face_mesh.FACEMESH_IRISES,
                    landmark_drawing_spec=None,
                    connection_drawing_spec=mp.solutions.drawing_styles
                    .get_default_face_mesh_iris_connections_style())

            return annotated_image
    except:
        return rgb_image


def plot_face_blendshapes_bar_graph(result):
    try:
        face_blendshapes = result.face_blendshapes[0]
        # Extract the face blendshapes category names and scores.
        face_blendshapes_names = [
            face_blendshapes_category.category_name for face_blendshapes_category in face_blendshapes]
        face_blendshapes_scores = [
            face_blendshapes_category.score for face_blendshapes_category in face_blendshapes]
        # The blendshapes are ordered in decreasing score value.
        face_blendshapes_ranks = range(len(face_blendshapes_names))

        fig, ax = plt.subplots(figsize=(12, 12))
        bar = ax.barh(face_blendshapes_ranks, face_blendshapes_scores,
                      label=[str(x) for x in face_blendshapes_ranks])
        ax.set_yticks(face_blendshapes_ranks, face_blendshapes_names)
        ax.invert_yaxis()

        # Label each bar with values
        for score, patch in zip(face_blendshapes_scores, bar.patches):
            plt.text(patch.get_x() + patch.get_width(),
                     patch.get_y(), f"{score:.4f}", va="top")

        ax.set_xlabel('Score')
        ax.set_title("Face Blendshapes")
        plt.tight_layout()
        plt.show()
    except Exception as e:
        print(f"An exception has occurred: {type(e)} with args {e.args}")


class FaceTracker:
    def __init__(self):
        self.result = FaceLandmarkerResult
        self.landmarker = FaceLandmarker
        self.build()

    def build(self):
        def update_result(result, output_image: mp.Image, timestamp_ms: int):
            self.result = result

        options = FaceLandmarkerOptions(
            base_options=BaseOptions(
                model_asset_path=MODEL_PATH),
            running_mode=VisionRunningMode.LIVE_STREAM,
            result_callback=update_result,
            num_faces=1,
            output_face_blendshapes=True
        )

        self.landmarker = self.landmarker.create_from_options(options)

    def detect_async(self, frame):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame)

        self.landmarker.detect_async(
            image=mp_image, timestamp_ms=int(time.time() * 1000))

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.landmarker.close()
        return True


async def echo(websocket: ServerConnection, conn: aioprocessing.AioConnection, interval):
    await websocket.send("Initializing streaming")
    print("Client connected")
    while True:
        try:
            data = conn.recv()
            await websocket.send(json.dumps(data))
        except ConnectionClosed:
            print("Client disconnected")
            break
        except EOFError:
            print("Pipe connection closed")
            break
        except Exception as e:
            print(f"Echo exception: {type(e)}: {e.args}")

        await asyncio.sleep(interval)


def capture_face(conn: aioprocessing.AioConnection):
    print("Getting video")
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print("Could not open video device")
        return

    with FaceTracker() as t:
        while True:
            ret, image = cap.read()

            if not ret:
                print("Error: failed to capture frame")
                continue

            t.detect_async(image)

            # If there's no face, don't do anything on exceptions
            try:
                if t.result.face_blendshapes[0] != []:
                    conn.send(
                        [category.score for category in t.result.face_blendshapes[0]])
            except IndexError:
                pass
            except AttributeError:
                pass
            except EOFError:
                break
            except Exception as e:
                print(f"Processor exception: {type(e)}: {e.args}")

            # Makes everything black. Comment to restore webcam
            image[:] = 0
            image = draw_landmarks_on_image(image, t.result)

            cv2.imshow('Webcam', image)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        cap.release()
        cv2.destroyAllWindows()


async def main():
    sensor_conn, sender_conn = aioprocessing.AioPipe()

    sender = functools.partial(
        echo, conn=sender_conn, interval=1/SENDING_FREQUENCY)

    sensor = aioprocessing.AioProcess(
        target=capture_face, args=(sensor_conn,))
    async with serve(handler=sender, host=SOCKET_HOST, port=SOCKET_PORT) as server:
        sensor.start()
        print(f"Serving at ws://{SOCKET_HOST}:{SOCKET_PORT}")
        await server.serve_forever()

    # sensor.join()


if __name__ == '__main__':
    asyncio.run(main())
