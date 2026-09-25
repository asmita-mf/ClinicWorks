import requests
import streamlit as st

from app.services.api import (
    get_processed_documents,
    retry_document,
)


def render_documents_section():

    documents_header_col, refresh_col = st.columns(
        [8, 1]
    )

    with documents_header_col:
        st.header("📋 Processed Documents")

    with refresh_col:

        if st.button(
            "🔄 Refresh",
            key="refresh_documents",
        ):
            st.rerun()

    try:

        response = get_processed_documents()

        if response.status_code != 200:

            st.error(
                f"Failed to load documents: "
                f"{response.status_code}"
            )

            return

        result = response.json()

        documents = result.get(
            "documents",
            [],
        )

        if not documents:

            st.info(
                "No processed documents found."
            )

            return

        render_table_header()

        for document in documents:

            render_document_row(
                document
            )

    except requests.Timeout:

        st.warning(
            "The processed documents request timed out. "
            "Please check the FastAPI and PostgreSQL connection."
        )

    except requests.ConnectionError:

        st.warning(
            "Could not connect to FastAPI. "
            "Please make sure the FastAPI server is running."
        )

    except requests.RequestException as exc:

        st.warning(
            f"Unable to load processed documents: {exc}"
        )


def render_table_header():

    header_cols = st.columns(
        [2.5, 1.5, 1.2, 1.2, 2.0, 1.2]
    )

    header_cols[0].markdown(
        "**Filename**"
    )

    header_cols[1].markdown(
        "**Blood Pressure**"
    )

    header_cols[2].markdown(
        "**HbA1c**"
    )

    header_cols[3].markdown(
        "**Status**"
    )

    header_cols[4].markdown(
        "**Created At**"
    )

    header_cols[5].markdown(
        "**Action**"
    )

    st.divider()


def render_document_row(document):

    document_id = document.get("id")

    filename = document.get(
        "filename",
        "-",
    )

    blood_pressure = document.get(
        "blood_pressure"
    ) or "-"

    hba1c = document.get(
        "hba1c"
    ) or "-"

    status = document.get(
        "status",
        "-",
    )

    created_at = document.get(
        "created_at"
    )

    if created_at:

        created_at = str(
            created_at
        ).replace(
            "T",
            " ",
        )

    else:

        created_at = "-"

    row_cols = st.columns(
        [2.5, 1.5, 1.2, 1.2, 2.0, 1.2]
    )

    with row_cols[0]:
        st.write(filename)

    with row_cols[1]:
        st.write(blood_pressure)

    with row_cols[2]:
        st.write(hba1c)

    with row_cols[3]:
        st.write(status)

    with row_cols[4]:
        st.write(created_at)

    with row_cols[5]:

        retry_clicked = st.button(
            "🔄 Retry",
            key=f"retry_{document_id}",
        )

    if retry_clicked:

        handle_retry(
            document_id,
            filename,
        )

    st.divider()


def handle_retry(document_id, filename):

    with st.spinner(
        f"Retrying {filename}..."
    ):

        try:

            response = retry_document(
                document_id
            )

            if response.status_code == 200:

                result = response.json()

                st.success(
                    result.get(
                        "message",
                        "Document retry started successfully.",
                    )
                )

                st.rerun()

            else:

                st.error(
                    f"Retry failed: "
                    f"{response.status_code} - "
                    f"{response.text}"
                )

        except requests.RequestException as exc:

            st.error(
                f"Could not connect to FastAPI: "
                f"{exc}"
            )