import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { File } from 'file-api';
import 'custom-event-autopolyfill';
import sinon from 'sinon';
import { clearFallbacks,
         handleUploadedPhoto,
         setupTextArea,
         setupClearPhotoButton,
         handleSubmitClick } from '../../web/static/js/support-form';

describe('support form', () => {
  let $;
  jsdom();

  beforeEach(() => {
    $ = jsdom.rerequire('jquery');
    $('body').append('<div id="test"></div>');
  });

  afterEach(() => {
    $('#test').remove();
  });

  describe('clearFallbacks', () => {
    beforeEach(() => {
      $('#test').html(`
        <button class="upload-photo-button" tabindex="-1"><label for="photo" tabindex="0"></label></button>
        <input type="file" id="photo" name="photo" />
        <div class="support-form-expanded"></div>
      `);
      clearFallbacks($);
    });

    it('resets tabindex attributes in the photo section to their defaults', () => {
      assert.equal($('.upload-photo-button').prop('tabindex'), 0);
      assert.equal($('label[for=photo]').prop('tabindex'), -1);
    });

    it('forwards a click on the button to the input', (done) => {
      $('#photo').click(() => done());
      $('.upload-photo-button').click();
    });
  });

  describe('setupClearPhotoButton', () => {
    beforeEach(() => {
      $('#test').html(`
        <input id="photo" />
        <button class="clear-photo"></button>
      `);
      setupClearPhotoButton($);
    });

    it('clears the photo input and triggers a change event', (done) => {
      $('#photo').val('test').change(() => { done(); });
      $('.clear-photo').click();
      assert.equal($('#photo').val(), '');
    });
  });

  describe('handleUploadedPhoto', () => {
    beforeEach(() => {
      $('#test').html(`
     <div class="photo-preview-container hidden-xs-up" tabindex="-1">
       <strong></strong>
       <div class="photo-preview"></div>
     </div>
     <button class="upload-photo-button hidden-xs-up"></button>
     `);
      handleUploadedPhoto(
        $,
        new File({name: 'test-file', buffer: new Buffer("this is a 24 byte string"), type: "image/png"}),
        $('.photo-preview'),
        $('.photo-preview-container')
      );
    });

    it('displays a preview of uploaded files', () => {
      const $preview = $('.photo-preview')
      assert.equal($preview.length, 1);
      assert.include($preview.html(), 'test-file');
      assert.include($preview.html(), '24 B');
    });

    it('shows a success message', () => {
      assert.include($('.support-success').text(), 'Photo successfully uploaded.');
    });

    it('hides the upload button', () => {
      assert.isTrue($('.upload-photo-button').hasClass('hidden-xs-up'));
    });
  });

  describe('setupTextArea', () => {
    function enterComment(comment) {
      const $textarea = $('#comments');
      $textarea.val(comment);
      $textarea.blur();
    };

    beforeEach(() => {
      $('#test').html(`
        <div class="form-group">
          <textarea id="comments"></textarea>
          <small class="form-text"></small>
        </div>
        <div class="support-form-expanded hidden-xs-up"></div>
        <button class="edit-comments"></button>
      `);
      setupTextArea($);
    });

    it('shows the rest of the form on focus', () => {
      $('#comments').focus();
      assert.equal($('.support-form-expanded').css('display'), 'block');
    });

    it('tracks the number of characters entered', () => {
      const $textarea = $('#comments')
      $textarea.val('12345');
      $textarea.keyup();
      assert.equal($('.form-text').text(), '5/3000 characters');
    });
  });

  describe('handleSubmitClick', () => {
    var spy;

    beforeEach(() => {
      spy = sinon.spy($, 'ajax');
      $('#test').html(`
        <div class="form-container">
          <form id="support-form" action="/customer-support">
            <textarea id="comments"></textarea>
            <div class="support-comments-error-container hidden-xs-up"><div class="support-comments-error"></div></div>
            <input id="photo" type="file" />
            <input id="phone" />
            <input id="email" />
            <div class="support-contacts-error-container hidden-xs-up"><div class="support-contacts-error"></div></div>
            <input id="privacy" type="checkbox" />
            <div class="support-privacy-error-container hidden-xs-up"><div class="support-privacy-error"></div></div>
            <div class="support-form-expanded" style="display: none"></div>
            <button id="support-submit"></button>
          </form>
        </div>
        <div class="support-thank-you hidden-xs-up"></div>
      `);
      handleSubmitClick($);
    });

    afterEach(() => {
      $.ajax.restore();
    });

    it('expands the form if it is hidden', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-form-expanded').hasClass('hidden-xs-up'));
      assert.isTrue($('.support-thank-you').hasClass('hidden-xs-up'));
    });

    it('requires text in the main textarea', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-comments-error-container').hasClass('hidden-xs-up'));
    });

    it('requires the privacy box to be checked', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-privacy-error-container').hasClass('hidden-xs-up'));
    });

    it('requires either a phone number or an email', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-contacts-error-container').hasClass('hidden-xs-up'));
    });

    it('requires a valid email', () => {
      $('#email').val('not an email');
      $('#support-submit').click();
      assert.isFalse($('.support-contacts-error-container').hasClass('hidden-xs-up'));
      $('#email').val('test@email.com');
      $('#support-submit').click();
      assert.isTrue($('.support-contacts-error-container').hasClass('hidden-xs-up'));
    });

    it('hides the form and shows a message on success', () => {
      $('#email').val('test@email.com');
      $('#comments').val('A comment');
      $('#privacy').prop('checked', 'checked');
      $('#support-submit').click();
      assert.equal(spy.callCount, 1);
      const ajaxArgs = spy.firstCall.args[0];
      assert.propertyVal(ajaxArgs, 'method', 'POST');
      assert.propertyVal(ajaxArgs, 'url', '/customer-support');
      ajaxArgs.success();
      assert.equal($('.form-container').length, 0);
      assert.isFalse($('.support-thank-you').hasClass('hidden-xs-up'));
    });

    it('shows a message on error', () => {
      $('#email').val('test@email.com');
      $('#comments').val('A comment');
      $('#privacy').prop('checked', 'checked');
      $('#support-submit').click();
      spy.firstCall.args[0].error();
      assert.isFalse($('.support-form-error').hasClass('hidden-xs-up'));
    });
  });
});
