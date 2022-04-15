/*
 * Copyright (c) 2013, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.xdf.ui.properties;

import java.util.HashMap;
import java.util.Map;

import org.eclipse.core.runtime.Platform;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.TraverseEvent;
import org.eclipse.swt.events.TraverseListener;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.ui.views.properties.tabbed.TabbedPropertySheetPage;

/**
 * This is a base class for property sections which need to display a list of
 * label/input. It configure the main layout in GridLayout.
 * 
 * @author Antoine Lorence
 * 
 */
public abstract class AbstractGridBasedSection extends AbstractDiagramSection {

	protected GridData fillHorizontalData;

	private boolean listenerSet = false;

	private final Map<Widget, Object> initialialValues = new HashMap<Widget, Object>();

	/** See {@link #addHiddenTextFieldToForm(Composite)} javadoc for information */
	private Text fake;

	@Override
	public void createControls(Composite parent,
			TabbedPropertySheetPage aTabbedPropertySheetPage) {
		super.createControls(parent, aTabbedPropertySheetPage);

		final GridLayout gridLayout = new GridLayout(2, false);
		fillHorizontalData = new GridData(SWT.FILL, SWT.BEGINNING, true, true);

		// Set GridLayout as default for a properties section
		formBody.setLayout(gridLayout);

		addHiddenTextFieldToForm(formBody);
	}

	@Override
	public void refresh() {
		super.refresh();

		final Control[] widgetList = formBody.getChildren();

		// Update initial values
		for (final Control widget : widgetList) {
			initialialValues.put(widget, getValue(widget));
		}

		// Fix related to a bug. See addHiddenTextFieldToForm() javadoc
		if (fake != null && !fake.isDisposed()) {
			fake.setFocus();
		}

		// Set listeners if not already set
		if (listenerSet)
			return;
		for (final Control widget : widgetList) {

			widget.addFocusListener(new FocusAdapter() {
				@Override
				public void focusLost(FocusEvent e) {
					final Widget widget = e.widget;
					if (checkValueValid(e.widget) == null
							&& !getValue(widget).equals(
									initialialValues.get(widget))) {
						writeValuesInTransaction(widget);
						initialialValues.put(widget, getValue(widget));
					}
				}
			});

			widget.addTraverseListener(new TraverseListener() {
				@Override
				public void keyTraversed(TraverseEvent e) {
					// User press the RETURN key
					if (e.detail == SWT.TRAVERSE_RETURN
							&& checkValueValid(e.widget) == null) {
						final Widget widget = e.widget;
						writeValuesInTransaction(widget);
						initialialValues.put(widget, getValue(widget));
					}
				}
			});

			if (widget instanceof Text) {
				widget.addKeyListener(new KeyListener() {

					@Override
					public void keyReleased(KeyEvent e) {
						final String validMsg = checkValueValid(e.widget);
						if (validMsg != null) {
							widget.setBackground(errorColor);
							widget.setToolTipText(validMsg);
						} else {
							widget.setBackground(null);
							widget.setToolTipText(null);
						}
					}

					@Override
					public void keyPressed(KeyEvent e) {
					}
				});
			}
		}

		listenerSet = true;
	}

	@Override
	public void dispose() {
		super.dispose();
		listenerSet = false;
	}

	/**
	 * Return the value contained by a given widget. This method must be able to
	 * read value from all widgets used across properties pages.
	 * 
	 * @param widget
	 * @return The value
	 */
	protected Object getValue(Widget widget) {
		if (widget instanceof Text) {
			return ((Text) widget).getText();
		}
		// Implements this getter for other kind of widgets
		return null;
	}

	/**
	 * I need to apologies for that... Because of the Orcc issue #68 related to
	 * the eclipse/SWT bug 383750, Mac OS users had problems when focusing on a
	 * Text field different from the first on the page.
	 * 
	 * To avoid that, we create a hidden Text, and we ensure this text is
	 * focused when refresh() method is called. With that trick, before user
	 * click the first time on a field, this one has take the (wrong) value set
	 * by SWT on first focus.
	 * 
	 * This awful workaround should be deleted if the bug 383750 on
	 * bugs.eclipse.org is fixed.
	 * 
	 * @param formBody
	 * @see <a
	 *      href="https://github.com/orcc/orcc/issues/68">https://github.com/orcc/orcc/issues/68</a>
	 * @see <a
	 *      href="https://bugs.eclipse.org/bugs/show_bug.cgi?id=383750">https://bugs.eclipse.org/bugs/show_bug.cgi?id=383750</a>
	 */
	private void addHiddenTextFieldToForm(final Composite formBody) {
		// This fix applies only on Mac OS systems
		if (!Platform.getOS().equals(Platform.OS_MACOSX)) {
			return;
		}

		// The grid data used to reduce space of the fake Text field
		final GridData hiddenData = new GridData(0, 0);
		// It takes 2 columns spaces in the table
		hiddenData.horizontalSpan = 2;

		// The fake Text field
		fake = widgetFactory.createText(formBody, "");
		fake.setLayoutData(hiddenData);

		// Here is the trick. To hide the fake Text field, we change top margin
		// value to move the content up, and bottom margin to prevent from
		// cropping the end of the table content. This is very bad, but it
		// works.
		((GridLayout) formBody.getLayout()).marginHeight = -5; // default was 5
		((GridLayout) formBody.getLayout()).marginBottom = 10; // default was 0
	}
}
