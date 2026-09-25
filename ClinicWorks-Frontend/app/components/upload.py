import streamlit as st
import requests

from app.services.api import upload_document


def render_upload_section():

    st.header("📄 Upload Clinical Document")

    uploaded_file = st.file_uploader(
        "Choose a clinical document",
        type=["pdf", "png", "jpg", "jpeg"],
    )

    if not uploaded_file:
        return

    st.success(
        f"Selected file: {uploaded_file.name}"
    )

    if st.button(
        "⚙️ Process Document",
        type="primary",
    ):

        with st.spinner(
            "Uploading and processing document..."
        ):

            try:

                response = upload_document(
                    uploaded_file
                )

                if response.status_code == 200:

                    result = response.json()

                    st.success(
                        result.get(
                            "message",
                            "Document processing started successfully.",
                        )
                    )

                    col1, col2, col3 = st.columns(3)

                    with col1:
                        st.metric(
                            "File",
                            result.get(
                                "filename",
                                uploaded_file.name,
                            ),
                        )

                    with col2:
                        st.metric(
                            "Status",
                            result.get(
                                "status",
                                "processing",
                            ),
                        )

                    with col3:
                        st.metric(
                            "Logic App",
                            result.get(
                                "logic_app_status",
                                "-",
                            ),
                        )

                else:

                    st.error(
                        f"Processing failed: "
                        f"{response.status_code} - "
                        f"{response.text}"
                    )

            except requests.RequestException as exc:

                st.error(
                    f"Could not connect to FastAPI: {exc}"
                )