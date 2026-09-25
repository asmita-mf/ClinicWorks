import streamlit as st


def render_header():
    st.title("🏥 ClinicWorks")

    st.subheader(
        "Clinical Document Processing"
    )

    st.write(
        "Upload a clinical document to extract and process "
        "Blood Pressure and HbA1c measurements."
    )

    st.divider()