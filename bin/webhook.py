#!/usr/bin/env python3
import requests
import sys
import os
import zipfile

def send_notification(webhook_url, not_ok_string_not_equals, not_ok_string_equals, not_ok_string_see_more, git_run_url):
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
                        "header": '%d previous failed, %d new failed' % (len(not_ok_string_equals.split('\n')) if not_ok_string_equals else 0, len(not_ok_string_not_equals.split('\n')) if not_ok_string_not_equals else 0),
                        "collapsible": True,
                        "uncollapsibleWidgetsCount": 2,
                        "widgets": [
                            {
                                "textParagraph": {
                                    "text": not_ok_string_equals
                                }
                            },
                            {
                                "textParagraph": {
                                    "text": not_ok_string_not_equals
                                }
                            },
                            {
                                "textParagraph": {
                                    "text": not_ok_string_see_more
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

def send_clean_notification(webhook_url, not_ok_string_equals, git_run_url):
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
                        "header": '%d known failed' % len(not_ok_string_equals.split('\n')) ,
                        "collapsible": False,
                        "uncollapsibleWidgetsCount": 0,
                        "widgets": [
                            {
                                "textParagraph": {
                                    "text": not_ok_string_equals
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

def filter_equals(github_repository, github_token):
    equals = []
    not_equals = []

    get_old_artifact(github_repository, github_token)
    # open .tap and read all lines
    with open("/app/report/results.tap", "r") as file:
        lines = file.readlines()
    
    with open("/app/report/results-old.tap", "r") as file_old:
        lines_old = file_old.readlines()

    # Iterate over the elements of both lists simultaneously
    for string1, string2 in zip(lines, lines_old):
        # Compare matching strings
        if string1 == string2:
            equals.append(string1)
        else:
            not_equals.append(string1)

    # filter all lines of equals if starts with "not ok" and save in list
    not_ok_line_see_more = [line for line in lines if line.startswith("#")]
    not_ok_string_see_more = "".join(not_ok_line_see_more)
    not_ok_line_equals = [line.strip()[7:] for line in equals if line.startswith("not ok")]
    not_ok_string_equals = "\n".join(not_ok_line_equals)

    # filter all lines of not_equals if starts with "not ok" and save in list
    not_ok_line_not_equals = [line.strip()[7:] for line in not_equals if line.startswith("not ok")]
    not_ok_string_not_equals = "\n".join(not_ok_line_not_equals)

    not_ok_string_not_equals, not_ok_string_see_more = remove_flaky(not_ok_string_not_equals, not_ok_string_see_more)

    return not_ok_string_not_equals, not_ok_string_equals, not_ok_string_see_more

def get_old_artifact(github_repository, github_token):
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {github_token}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    url = f"https://api.github.com/repos/{github_repository}/actions/artifacts"
    response = requests.get(url, headers=headers)
    # Convert the response to JSON
    data = response.json()
    # Get the URL of the second artifact
    artifact_url = data['artifacts'][1]['archive_download_url']
    print(artifact_url) # debug
    response = requests.get(artifact_url, headers=headers)
    if response.status_code == 200:
        # Full file path
        caminho_arquivo = os.path.join('/app/report', 'results-old.zip')
        pasta_destino = '/app/report'
        # Save artifact contents to a local file
        with open(caminho_arquivo, 'wb') as f:
            f.write(response.content)
        # Extract contents from ZIP
        with zipfile.ZipFile(caminho_arquivo, 'r') as zip_ref:
            zip_ref.extractall()

        # Set the new path
        novo_caminho_arquivo = os.path.join(pasta_destino, "results-old.tap")

        # Rename the extracted file to results-old.tap
        os.rename('/app/results.tap', novo_caminho_arquivo)
    else:
        print("Erro ao baixar o artefato:", response.status_code)

def remove_flaky(not_ok_string_not_equals, not_ok_string_see_more):
    lines = not_ok_string_not_equals.count('\n') + 1
    exit_status_1=not_ok_string_see_more.count("exit status: 1")
    if lines == exit_status_1:
        return 0,0
    return not_ok_string_not_equals, not_ok_string_see_more

def main():
    if len(sys.argv) != 6:
        print("Please, send WEBHOOK_URL, WEBHOOK_CLEAN_URL, GITHUB_REPOSITORY, GITHUB_RUN_ID and github_token with arguments.")
        return
    
    if not os.path.exists('/app/report/results.tap'):
        print("Error: The file '/app/report/results.tap' does not exist.")
        return
    
    webhook_url = sys.argv[1]
    webhook_clean_url = sys.argv[2]
    github_repository = sys.argv[3]
    github_run_id = sys.argv[4]
    github_token = sys.argv[5]
    git_run_url = f"https://github.com/{github_repository}/actions/runs/{github_run_id}"

    not_ok_string_not_equals, not_ok_string_equals, not_ok_string_see_more = filter_equals(github_repository, github_token)
    
    if not_ok_string_not_equals or not_ok_string_equals:
        send_notification(webhook_url, not_ok_string_not_equals, not_ok_string_equals, not_ok_string_see_more, git_run_url)

    if not_ok_string_equals:
        send_clean_notification(webhook_clean_url, not_ok_string_equals, git_run_url)

if __name__ == "__main__":
    main()
