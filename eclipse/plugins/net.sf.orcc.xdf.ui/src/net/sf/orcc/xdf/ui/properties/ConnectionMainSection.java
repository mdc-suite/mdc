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

import net.sf.orcc.df.Connection;
import net.sf.orcc.xdf.ui.util.XdfUtil;

import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.ui.views.properties.tabbed.TabbedPropertySheetPage;

/**
 * Displayed in Main tab when a connection is selected.
 * 
 * @author Antoine Lorence
 * 
 */
public class ConnectionMainSection extends AbstractGridBasedSection {

	private Text connectionSize;

	@Override
	protected String getFormText() {
		return "Connection Properties";
	}

	@Override
	public void createControls(Composite parent, TabbedPropertySheetPage tabbedPropertySheetPage) {
		super.createControls(parent, tabbedPropertySheetPage);

		widgetFactory.createCLabel(formBody, "Size:");

		connectionSize = widgetFactory.createText(formBody, "", SWT.BORDER);
		connectionSize.setLayoutData(fillHorizontalData);
	}

	@Override
	protected void readValuesFromModels() {
		final Connection connection = (Connection) getSelectedBusinessObject();
		if (connection.getSize() != null) {
			connectionSize.setText(connection.getSize().toString());
		} else {
			// Reset field in case it was filled before
			connectionSize.setText("");
		}
	}

	@Override
	protected String checkValueValid(Widget widget) {

		if (widget == connectionSize && !connectionSize.getText().isEmpty()) {
			try {
				Integer size = Integer.parseInt(connectionSize.getText());
				if (size <= 0) {
					return "Size must be a positive integer";
				}
				// Check if size is a power of 2:
				else if ((size & (size - 1)) != 0) {
					// It is not a power of 2
					return "Size must be a power of 2";
				}
			} catch (NumberFormatException e) {
				return "Unable to parse this size. Please use only integer characters.";
			}
		}
		return null;
	}

	@Override
	protected void writeValuesToModel(final Widget widget) {
		final Connection connection = (Connection) getSelectedBusinessObject();
		if(widget == connectionSize) {
			if (connectionSize.getText().isEmpty()) {
				connection.unsetSize();
				return;
			}
			try {
				final String sizeText = connectionSize.getText();
				final Integer bufferSize = Integer.parseInt(sizeText);
				connection.setSize(bufferSize);
			} catch (NumberFormatException e) {
				MessageDialog.openError(XdfUtil.getDefaultShell(), "Syntax error",
						"Unable to parse the size you entered.");
			}
		}
	}
}
