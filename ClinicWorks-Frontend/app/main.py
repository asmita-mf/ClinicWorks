import streamlit as st

from app.components.header import render_header
from app.components.upload import render_upload_section
from app.components.documents import render_documents_section


st.set_page_config(
    page_title="ClinicWorks",
    page_icon="🏥",
    layout="wide",
)


def main():

    render_header()

    render_upload_section()

    st.divider()

    render_documents_section()


if __name__ == "__main__":
    main()