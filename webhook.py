import os
import requests

def send_notification(webhook_url, not_ok_string, git_run_url):
    if not_ok_string:
        app_message ={
            'cardsV2': [{
                'cardId': 'createCardMessage',
                'card': {
                    'header': {
                        'title': 'Error',
                        'subtitle': '',
                        'imageUrl': 'https://avatars.githubusercontent.com/u/146738539?s=200&v=4',
                        'imageType': 'CIRCLE'
                    },
                    'sections': [
                        {
                            "header": '%d tests failed' % len(not_ok_string.split('\n')),
                            "collapsible": True,
                            "uncollapsibleWidgetsCount": 0,
                            "widgets": [
                                {
                                    "textParagraph": {
                                        "text": not_ok_string
                                    }
                                },
                                {
                                    'buttonList': {
                                        'buttons': [
                                            {
                                                'text': 'View results',
                                                'onClick': {
                                                    'openLink': {
                                                        'url': git_run_url
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                }
                            ]
                        }
                    ]
                }
            }]
        }

        message_headers = {"Content-Type": "application/json; charset=UTF-8"}
        requests.post(webhook_url, json=app_message, headers= message_headers)

def main():
    webhook_url = os.environ['WEBHOOK_URL']
    git_run_url = f"https://github.com/marmotitude/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}"

    # open .tap and read all lines
    with open("/app/report/results.tap", "r") as file:
        lines = file.readlines()

    # filter all lines if starts with "not ok"
    not_ok_line = [line.strip()[7:] for line in lines if line.startswith("not ok")]

    # List of lines in string
    not_ok_string = "\n".join(not_ok_line)

    # only send notifications to gchat on failures
    if not_ok_string:
      send_notification(webhook_url, not_ok_string, git_run_url)

if __name__ == "__main__":
    main()
    