defmodule LiveDj.ViewCase do
  @moduledoc """
  This module defines functions that get, set or query, or interact with views.

  You may define functions here to be used as helpers in
  your tests.
  """

  import Phoenix.LiveViewTest

  @chat_section_tab_button "#show-room-chat-section-tab"
  @pause_button_id "#player_signal_paused"
  @play_button_id "#player_signal_playing"
  @play_next_button_id "#player_signal_play_next"
  @play_previous_button_id "#player_signal_play_previous"
  @player_controls_save_queue_button_id "#player-controls-save-queue"
  @room_settings_modal_button_id "#aside-room-settings-modal-button"
  @room_edit_form_id "#room-edit-form"

  def button(view, "pause"), do: element(view, @pause_button_id)
  def button(view, "play"), do: element(view, @play_button_id)
  def button(view, "play_next"), do: element(view, @play_next_button_id)
  def button(view, "play_previous"), do: element(view, @play_previous_button_id)
  def button(view, "room_settings"), do: element(view, @room_settings_modal_button_id)
  def button(view, "save_queue"), do: element(view, @player_controls_save_queue_button_id)
  def button(view, "chat_section_tab"), do: element(view, @chat_section_tab_button)
  def button(view, button_id), do: element(view, button_id)

  def get_form(view, "room_edit"), do: element(view, @room_edit_form_id)

  def click(view, type), do: button(view, type) |> render_click()
  def has_button(view, type), do: button(view, type) |> has_element?()
  def has_form(view, type), do: get_form(view, type) |> has_element?()
end
