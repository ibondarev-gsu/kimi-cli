"""Tests for normalize_history in the dynamic_injection module."""

from __future__ import annotations

from kosong.message import ContentPart, ImageURLPart, Message, TextPart

from kimi_cli.soul.dynamic_injection import normalize_history


def _text(part: ContentPart) -> str:
    assert isinstance(part, TextPart)
    return part.text


def test_empty_history() -> None:
    assert normalize_history([]) == []


def test_single_user_message() -> None:
    msgs = [Message(role="user", content=[TextPart(text="hello")])]
    result = normalize_history(msgs)
    assert len(result) == 1
    assert result[0].role == "user"
    assert _text(result[0].content[0]) == "hello"


def test_single_assistant_message() -> None:
    msgs = [Message(role="assistant", content=[TextPart(text="hi")])]
    result = normalize_history(msgs)
    assert len(result) == 1
    assert result[0].role == "assistant"


def test_adjacent_user_messages_merged() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="A")]),
        Message(role="user", content=[TextPart(text="B")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 1
    assert result[0].role == "user"
    # Consecutive TextParts are coalesced into a single TextPart.
    assert len(result[0].content) == 1
    assert _text(result[0].content[0]) == "A\n\nB"


def test_three_adjacent_user_messages_merged() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="A")]),
        Message(role="user", content=[TextPart(text="B")]),
        Message(role="user", content=[TextPart(text="C")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 1
    assert len(result[0].content) == 1
    assert _text(result[0].content[0]) == "A\n\nB\n\nC"


def test_non_adjacent_users_not_merged() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="A")]),
        Message(role="assistant", content=[TextPart(text="X")]),
        Message(role="user", content=[TextPart(text="B")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 3
    assert result[0].role == "user"
    assert result[1].role == "assistant"
    assert result[2].role == "user"


def test_adjacent_assistant_not_merged() -> None:
    msgs = [
        Message(role="assistant", content=[TextPart(text="X")]),
        Message(role="assistant", content=[TextPart(text="Y")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 2


def test_mixed_roles_complex() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="A")]),
        Message(role="user", content=[TextPart(text="B")]),
        Message(role="assistant", content=[TextPart(text="X")]),
        Message(role="user", content=[TextPart(text="C")]),
        Message(role="user", content=[TextPart(text="D")]),
        Message(role="assistant", content=[TextPart(text="Y")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 4
    assert result[0].role == "user"
    assert len(result[0].content) == 1  # A + B coalesced
    assert _text(result[0].content[0]) == "A\n\nB"
    assert result[1].role == "assistant"
    assert result[2].role == "user"
    assert len(result[2].content) == 1  # C + D coalesced
    assert _text(result[2].content[0]) == "C\n\nD"
    assert result[3].role == "assistant"


def test_multipart_content_preserved() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="A"), TextPart(text="B")]),
        Message(role="user", content=[TextPart(text="C")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 1
    # All consecutive TextParts are coalesced into one.
    assert len(result[0].content) == 1
    assert _text(result[0].content[0]) == "A\n\nB\n\nC"


def test_notification_messages_not_merged_with_user_messages() -> None:
    msgs = [
        Message(role="user", content=[TextPart(text="user input")]),
        Message(
            role="user",
            content=[
                TextPart(
                    text='<notification id="n1" category="task" type="task.completed">x</notification>'
                )
            ],
        ),
    ]
    result = normalize_history(msgs)
    assert len(result) == 2


def test_text_parts_coalesced_around_image() -> None:
    """Only consecutive TextParts are merged; ImageURLPart stays separate."""
    msgs = [
        Message(role="user", content=[TextPart(text="A")]),
        Message(
            role="user",
            content=[
                ImageURLPart(
                    image_url=ImageURLPart.ImageURL(url="https://example.com/img.png")
                )
            ],
        ),
        Message(role="user", content=[TextPart(text="B")]),
    ]
    result = normalize_history(msgs)
    assert len(result) == 1
    assert len(result[0].content) == 3
    assert isinstance(result[0].content[0], TextPart)
    assert _text(result[0].content[0]) == "A"
    assert isinstance(result[0].content[1], ImageURLPart)
    assert isinstance(result[0].content[2], TextPart)
    assert _text(result[0].content[2]) == "B"
