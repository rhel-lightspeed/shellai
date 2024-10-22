import json
import logging
import os

import requests

from shellai.config import Config
from shellai.history import handle_history_read, handle_history_write
from shellai.utils import get_payload


def handle_script_session(shellai_tmp_file) -> None:
    """
    Starts a 'script' session and writes the PID to a file, but leaves control of the terminal to the user.
    """
    # Prepare the script command
    script_command = ["script", "-f", shellai_tmp_file]

    # Start the script session and leave control to the terminal
    os.system(" ".join(script_command))

    # Remove the captured output after the script session ends
    if os.path.exists(shellai_tmp_file):
        logging.info(f"Removing {shellai_tmp_file}")
        os.remove(shellai_tmp_file)


def _handle_caret(query: str, config: Config) -> str:
    """
    Replaces caret (^) with command output specified in config file.
    """
    if "^" not in query:
        return query

    captured_output_file = config.output.file

    if not os.path.exists(captured_output_file):
        logging.error(
            f"Output file {captured_output_file} does not exist, change location of file in config to use '^'."
        )
        exit(1)

    prompt_separator = config.output.prompt_separator
    with open(captured_output_file, "r") as f:
        # NOTE: takes only last command + output from file
        output = f.read().split(prompt_separator)[-1].strip()

    query = query.replace("^", "")
    query = f"Context data: {output}\nQuestion: " + query
    return query


def handle_query(query: str, config: Config) -> None:
    query = _handle_caret(query, config)
    # NOTE: Add more query handling here

    logging.info(f"Query: {query}")

    query_endpoint = config.backend.endpoint

    try:
        history = handle_history_read(config)
        payload = get_payload(query)
        logging.info("Waiting for response from AI...")
        response = requests.post(
            query_endpoint,
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload),
            timeout=30,  # waiting for more than 30 seconds does not make sense
        )
        response.raise_for_status()
        completion = response.json()
        response_data = completion.get("response", {})
        references = completion.get("referenced_documents", {})
        references = [
            f'{reference["title"]}: {reference["docs_url"]}' for reference in references
        ]
        references_str = (
            "\n\nReferences:\n" + "\n".join(references) if references else ""
        )
        handle_history_write(
            config,
            [
                *history,
                {"role": "user", "content": query},
            ],
            response_data,
        )
        print(response_data + references_str)
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to get response from AI: {e}")
        exit(1)
