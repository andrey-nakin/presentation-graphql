cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
project(PresentationGraphQL VERSION 1.0.0)
include(${PROJECT_SOURCE_DIR}/UseLATEX.cmake)

add_latex_document(src/graphql.tex
	INPUTS 
	FORCE_PDF
	)
